class profile::ncredir(
    Stdlib::Port $http_port = lookup('profile::ncredir::http_port', {default_value => 80}),
    Stdlib::Port $https_port = lookup('profile::ncredir::https_port', {default_value => 443}),
    Hash[String, Hash[String, Any]] $shared_acme_certificates = lookup('shared_acme_certificates'),
    String $acme_chief_cert_prefix = lookup('profile::ncredir::acme_chief_cert_prefix', {default_value => 'non-canonical-redirect-'}),
    Optional[String] $fqdn_monitoring = lookup('profile::ncredir::fqdn_monitoring', {default_value => undef}),
) {

    class { '::sslcert::dhparam': }
    class { 'nginx':
        variant => 'light',
    }

    class { '::ncredir':
        ssl_settings           => ssl_ciphersuite('nginx', 'compat'),
        redirection_maps       => compile_redirects('puppet:///modules/ncredir/nc_redirects.dat', 'nginx'),
        acme_certificates      => $shared_acme_certificates,
        acme_chief_cert_prefix => $acme_chief_cert_prefix,
        http_port              => $http_port,
        https_port             => $https_port,
    }

    $shared_acme_certificates.each |String $cert_name, Hash[String, Any] $cert_details| {
        if $cert_name =~ $acme_chief_cert_prefix {
            acme_chief::cert { $cert_name:
                puppet_svc => 'nginx',
                before     => Service['nginx'],
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

    if $fqdn_monitoring {
        monitoring::service { 'https_ncredir':
            description   => 'HTTPS',
            check_command => "check_ssl_http_letsencrypt!${fqdn_monitoring}",
            notes_url     => ['https://wikitech.wikimedia.org/wiki/Ncredir'],
        }
    }
}
