class profile::ncredir(
    Stdlib::Port $http_port = lookup('profile::ncredir::http_port', {default_value => 80}),
    Stdlib::Port $https_port = lookup('profile::ncredir::https_port', {default_value => 443}),
    Hash[String, Hash[String, Any]] $shared_acme_certificates = lookup('shared_acme_certificates'),
    String $acme_chief_cert_prefix = lookup('profile::ncredir::acme_chief_cert_prefix', {default_value => 'non-canonical-redirect-'}),
    Boolean $monitoring = lookup('profile::ncredir::monitoring', {default_value => false}),
    Wmflib::UserIpPort $mtail_access_log_port = lookup('profile::ncredir::mtail_access_log_port', {default_value => 3904}),
    Array[String] $prometheus_nodes = lookup('prometheus_nodes', {default_value => []}),
    Integer[0] $hsts_max_age = lookup('profile::ncredir::hsts_max_age', {default_value => 106384710}),
) {

    class { '::sslcert::dhparam': }
    class { 'nginx':
        variant => 'light',
    }

    mtail::program { 'ncredir':
        source      => 'puppet:///modules/mtail/programs/ncredir.mtail',
        destination => '/etc/ncredir.mtail',
        notify      => Service['ncredirmtail@access_log'],
    }

    profile::ncredir::log { 'access_log':
        ncredirmtail_port => $mtail_access_log_port,
    }

    class { '::ncredir':
        ssl_settings           => ssl_ciphersuite('nginx', 'compat'),
        redirection_maps       => compile_redirects('puppet:///modules/ncredir/nc_redirects.dat', 'nginx'),
        acme_certificates      => $shared_acme_certificates,
        acme_chief_cert_prefix => $acme_chief_cert_prefix,
        http_port              => $http_port,
        https_port             => $https_port,
        hsts_max_age           => $hsts_max_age,
        require                => File['/var/log/nginx/ncredir.access_log.pipe'],
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

    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
    ferm::service { 'mtail':
      proto  => 'tcp',
      port   => '3904',
      srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }
}
