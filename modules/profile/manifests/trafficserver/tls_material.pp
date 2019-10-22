# profile::trafficserver::tls_material gets various TLS material deployed and ready for ATS consumption
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
# [*do_ocsp*]
#   Boolean. Sets up OCSP Stapling for this server. This creates the OCSP data file itself
#   and ensures a cron is running to keep it up to date.
#   ACME support is provided via acme-chief only.

define profile::trafficserver::tls_material(
    String $instance_name,
    String $service_name = 'trafficserver',
    Stdlib::Absolutepath $tls_material_path = '/etc/trafficserver/tls',
    Stdlib::Absolutepath $ssl_multicert_path = '/etc/trafficserver/ssl_multicert.config',
    Boolean $default_instance = false,
    Optional[Array[String]] $certs = undef,
    Boolean $acme_chief = false,
    Optional[String] $acme_certname = $title,
    Boolean $do_ocsp = false,
    Optional[String] $ocsp_proxy = undef,
){
    if (empty($certs) and !$acme_chief) {
        fail('Provide $certs or enable $acme_chief support')
    }

    unless defined(File['/etc/ssl/dhparam.pem']) {
        class { '::sslcert::dhparam': }
    }

    unless defined(File[$tls_material_path]) {
        file { $tls_material_path:
            ensure => directory,
            owner  => 'root',
            group  => 'root',
        }
    }

    unless empty($certs) {
        $certs.each |String $cert| {
            unless defined(Sslcert::Certificate[$cert]) {
                sslcert::certificate { $cert:
                    before => Trafficserver::Instance[$instance_name],
                }
            }
        }
        unless defined(File["${tls_material_path}/oscerts"]) {
            file { "${tls_material_path}/oscerts":
                ensure => link,
                target => '/etc/ssl',
            }
        }
        if $do_ocsp and !defined(File["${tls_material_path}/osocsp"]) {
            file { "${tls_material_path}/osocsp":
                ensure  => link,
                target  => '/var/cache/ocsp',
                require => File['/var/cache/ocsp'],
            }
        }
    }

    if $acme_chief {
        if !defined(Acme_chief::Cert[$acme_certname]) {
            acme_chief::cert { $acme_certname:
                before => Trafficserver::Instance[$instance_name],
            }
        }
        unless defined(File["${tls_material_path}/acmecerts"]) {
            file { "${tls_material_path}/acmecerts":
                ensure  => link,
                target  => '/etc/acmecerts',
                require => File['/etc/acmecerts'],
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
        $ocsp_hook = "${service_name}-ocsp"

        if !defined(Sslcert::Ocsp::Hook[$ocsp_hook]) {
            sslcert::ocsp::hook { $ocsp_hook:
                content => template('profile/trafficserver/update-ocsp-trafficserver-hook.erb'),
            }
        }
    }

    if $do_ocsp and $acme_chief {
        # TODO: Remove it as soon as we get rid of nginx on the cp cluster and replace it with
        # the acme_chief::cert puppet_rsc parameter
        unless defined(Exec["refresh-tls-material-trafficserver-${instance_name}"]) {
            exec { "refresh-tls-material-trafficserver-${instance_name}":
                command     => "/usr/bin/touch ${ssl_multicert_path} && /bin/systemctl reload ${service_name}",
                refreshonly => true,
            }
        }
        File["/etc/acmecerts/${acme_certname}"] ~> Exec["refresh-tls-material-trafficserver-${instance_name}"]
    }
}
