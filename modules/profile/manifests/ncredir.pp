# SPDX-License-Identifier: Apache-2.0
class profile::ncredir(
    Stdlib::Port $http_port = lookup('profile::ncredir::http_port', {default_value                               => 80}),
    Stdlib::Port $https_port = lookup('profile::ncredir::https_port', {default_value                             => 443}),
    Hash[String, Hash[String, Any]] $shared_acme_certificates = lookup('certificates::acme_chief'),
    String $acme_chief_cert_prefix = lookup('profile::ncredir::acme_chief_cert_prefix', {default_value           => 'non-canonical-redirect-'}),
    Boolean $monitoring = lookup('profile::ncredir::monitoring', {default_value                                  => false}),
    Integer[0] $hsts_max_age = lookup('profile::ncredir::hsts_max_age', {default_value                           => 106384710}),
    String $benthos_address = lookup('profile::ncredir::benthos_address', {default_value                         => '127.0.0.1:1221'}),
) {

    class { '::sslcert::dhparam': }

    include ::profile::benthos

    class { '::ncredir':
        ssl_settings           => ssl_ciphersuite('nginx', 'strong'),
        redirection_maps       => wmflib::compile_redirects(file('ncredir/nc_redirects.dat'), 'nginx'),
        acme_certificates      => $shared_acme_certificates,
        acme_chief_cert_prefix => $acme_chief_cert_prefix,
        http_port              => $http_port,
        https_port             => $https_port,
        hsts_max_age           => $hsts_max_age,
        benthos_address        => $benthos_address,
    }

    $shared_acme_certificates.each |String $cert_name, Hash[String, Any] $cert_details| {
        if $cert_name =~ $acme_chief_cert_prefix {
            acme_chief::cert { $cert_name:
                puppet_rsc => Exec['nginx-reload'],
                before     => Service['nginx'],
            }

            if $monitoring {
                # Common name could be a wildcard
                $check_hostname = regsubst($cert_details['CN'], '^\*', 'www')

                monitoring::service { "https_ncredir_${cert_name}":
                    description   => "HTTPS ${cert_name}",
                    check_command => "check_ssl_http_letsencrypt_ocsp!${check_hostname}",
                    notes_url     => 'https://wikitech.wikimedia.org/wiki/Ncredir',
                }
            }
        }
    }

    # Firewall
    ferm::service { 'ncredir_http':
        proto => 'tcp',
        port  => $http_port,
    }
    ferm::service { 'ncredir_https':
        proto => 'tcp',
        port  => $https_port,
    }
}
