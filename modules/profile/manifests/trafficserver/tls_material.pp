# profile::rafficserver::tls_material gets various TLS material deployed and ready for ATS consumption
#
# [*instance_name*]
#   ATS instance name
#
# [*service_name*]
#   ATS service name. Defaults to 'trafficserver'
#
# [*ssl_multicert_path*]
#   ATS ssl_multicert.config absolute path. Defaults to '/etc/trafficserver/ssl_multicert.config'
#
# [*server_name*]
#   Server name, only used in the old LE puppetization. Defaults to FQDN
#
# [*certs*]
#   Optional - specify either this or acme_subjects.
#   Array of certs, normally just one.  If more than one, special patched nginx
#   support is required.  This is intended to support duplicate keys with
#   differing crypto (e.g. ECDSA + RSA).
#
# [*acme_chief*]
#   Optional - specify either this or acme_subjects.
#   If true, download, and potentially use, certificates from acme-chief.
#   If $certs is empty, acme-chief certificates will be used to serve traffic.
#   When used in conjunction with certs, acme-chief certificate will be deployed on
#   the server but certs specified in $certs will be used to serve traffic
#
# [*acme_certname*]
#   Optional - specify this if title of the resource and the acme-chief certname differs.
#
# [*acme_subjects*]
#   Optional - Enable the old LE puppetization. specify either this or certs.
#   This is also incompatible with using acme_chief
#   Array of certificate subjects, beginning with the canonical one - the rest
#   will be listed as Subject Alternative Names.
#   There should be no more than 100 entries in this.
#   This option will be removed in following changes. If you need to use LE certificates
#   please migrate to acme-chief ASAP.
#
# [*do_ocsp*]
#   Boolean. Sets up OCSP Stapling for this server. This creates the OCSP data file itself
#   and ensures a cron is running to keep it up to date.
#   ACME support is provided via acme-chief only.

define profile::trafficserver::tls_material(
    String $instance_name,
    String $service_name = 'trafficserver',
    Stdlib::Absolutepath $ssl_multicert_path = '/etc/trafficserver/ssl_multicert.config',
    Boolean $default_instance = false,
    String $server_name = $::fqdn,
    Optional[Array[String]] $certs = undef,
    Optional[Array[String]] $acme_subjects = undef,
    Boolean $acme_chief = false,
    Optional[String] $acme_certname = $title,
    Boolean $do_ocsp = false,
    Optional[String] $ocsp_proxy = undef,
){
    if (!empty($certs) and !empty($acme_subjects)) or ($acme_chief and !empty($acme_subjects)) or (empty($certs) and empty($acme_subjects) and !$acme_chief) {
        fail('Specify exactly one of certs (and optionally acme_chief) or acme_subjects')
    }

    unless defined(File['/etc/ssl/dhparam.pem']) {
        class { '::sslcert::dhparam': }
    }

    unless empty($certs) {
      $certs.each |String $cert| {
          unless defined(Sslcert::Certificate[$cert]) {
              sslcert::certificate { $cert:
                  before => Trafficserver::Instance[$instance_name],
              }
          }
      }
    }

    unless empty($acme_subjects) {
        unless defined(Letsencrypt::Cert::Integrated[$server_name]) {
            letsencrypt::cert::integrated { $server_name:
                subjects   => join($acme_subjects, ','),
                puppet_svc => $service_name,
                system_svc => $service_name,
            }
        }
    }

    if $acme_chief {
        if !defined(Acme_chief::Cert[$acme_certname]) {
            acme_chief::cert { $acme_certname:
                ocsp       => $do_ocsp,
                ocsp_proxy => $ocsp_proxy,
                before     => Trafficserver::Instance[$instance_name],
            }
        }
        if !empty($certs) # all TLS material must be under the same base directory to be used by ATS
        {
            file { "/etc/ssl/localcerts/acme-chief-${acme_certname}-live":
                ensure  => link,
                target  => "/etc/acmecerts/${acme_certname}/live",
                require => [File['/etc/ssl/localcerts'], Acme_Chief::Cert[$acme_certname]],
            }
            file { "/etc/ssl/private/acme-chief-${acme_certname}-live":
                ensure  => link,
                target  => "/etc/acmecerts/${acme_certname}/live",
                require => [File['/etc/ssl/private'], Acme_Chief::Cert[$acme_certname]],
            }
            if $do_ocsp {
                file { "/var/cache/ocsp/acme-chief-${acme_certname}-live":
                    ensure  => link,
                    target  => "/etc/acmecerts/${acme_certname}/live",
                    require => File['/var/cache/ocsp'],
                }
            }
        }
    }

    if $do_ocsp and !empty($certs) {
        $certs.each |String $cert| {
            unless defined(Sslcert::Ocsp::Conf[$cert]) {
                sslcert::ocsp::conf { $cert:
                    proxy  => $ocsp_proxy,
                    before => Trafficserver::Instance[$instance_name],
                }
            }
        }
    }

    if $do_ocsp {
        $ocsp_hook = "${service_name}-ocsp"

        if !defined(Sslcert::Ocsp::Hook[$ocsp_hook]) {
            sslcert::ocsp::hook { $ocsp_hook:
                content => template('profile/trafficserver/update-ocsp-trafficserver-hook.erb'),
            }
        }
    }
}
