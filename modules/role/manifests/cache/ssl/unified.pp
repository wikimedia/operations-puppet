class role::cache::ssl::unified {
    if ( $::realm == 'production' ) {
        monitoring::service { 'https':
            description   => 'HTTPS',
            check_command => 'check_sslxNN',
        }

        tlsproxy::localssl { 'unified':
            server_name    => 'www.wikimedia.org',
            certs          => ['ecc-uni.wikimedia.org', 'uni.wikimedia.org'],
            default_server => true,
            do_ocsp        => true,
            upstream_port  => 3127,
            redir_port     => 8080,
        }
    }
    else {
        $subjects = hiera('cache::cluster') ? {
            'upload' => 'upload.beta.wmflabs.org',
            'text'   => join(cache_ssl_beta_subjects(), ',')
        }
        $server_name = hiera('cache::cluster') ? {
            'upload' => 'upload.beta.wmflabs.org',
            'text'   => 'beta.wmflabs.org'
        }

        letsencrypt::cert::integrated { 'unified':
            subjects   => $subjects,
            puppet_svc => 'nginx',
            system_svc => 'nginx',
        }
        file { '/etc/ssl/localcerts/unified.crt':
            ensure => 'link',
            target => '/etc/acme/cert/unified.crt',
            owner  => 'root',
            group  => 'root',
            mode   => '0640',
        }
        file { '/etc/ssl/private/unified.key':
            ensure => 'link',
            target => '/etc/acme/key/unified.key',
            owner  => 'root',
            group  => 'root',
            mode   => '0640',
        }
        tlsproxy::localssl { 'unified':
            server_name    => $server_name,
            certs          => ['unified'],
            default_server => true,
            do_ocsp        => false,
            skip_private   => true,
            upstream_port  => 3127,
            redir_port     => 8080,
            from_puppet    => false,
            acme_challenge => true,
            require        => [
                File['/etc/ssl/localcerts/unified.crt'],
                File['/etc/ssl/private/unified.key'],
            ],
        }
    }

    # ordering ensures nginx/varnish config/service-start are
    #  not intermingled during initial install where they could
    #  have temporary conflicts on binding port 80
    Service['nginx'] -> Service<| tag == 'varnish_instance' |>
}
