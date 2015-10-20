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
        if ( hiera('cache::cluster') == 'upload' ) {
            letsencrypt::cert::integrated { 'upload':
                subjects   => 'upload.beta.wmflabs.org',
                puppet_svc => 'nginx',
                system_svc => 'nginx',
            }
            file { '/etc/ssl/localcerts/upload.crt':
                ensure => 'link',
                target => '/etc/acme/cert/upload.crt',
                owner  => 'root',
                group  => 'root',
                mode   => '0640',
            }
            file { '/etc/ssl/private/upload.key':
                ensure => 'link',
                target => '/etc/acme/key/upload.key',
                owner  => 'root',
                group  => 'root',
                mode   => '0640',
            }
            tlsproxy::localssl { 'unified':
                server_name    => 'upload.beta.wmflabs.org',
                certs          => ['upload'],
                default_server => true,
                do_ocsp        => false,
                skip_private   => true,
                upstream_port  => 3127,
                redir_port     => 8080,
                from_puppet    => false,
                acme_challenge => true,
                require        => [
                    File['/etc/ssl/localcerts/upload.crt'],
                    File['/etc/ssl/private/upload.key'],
                ],
            }
        } else {
            # TODO: Needs the ability to use a *LOT* of domains, no wildcards!
            #letsencrypt::cert::integrated { 'testing-le':
            #    subjects   => 'www.wikimedia.beta.wmflabs.org',
            #    puppet_svc => 'nginx',
            #    system_svc => 'nginx',
            #}

            tlsproxy::localssl { 'unified':
                server_name    => 'www.wikimedia.beta.wmflabs.org',
                certs          => ['star.star.beta.wmflabs.org'],
                default_server => true,
                do_ocsp        => false,
                skip_private   => true,
                upstream_port  => 3127,
                redir_port     => 8080,
                chain          => false,
            }
        }
    }

    # ordering ensures nginx/varnish config/service-start are
    #  not intermingled during initial install where they could
    #  have temporary conflicts on binding port 80
    Service['nginx'] -> Service<| tag == 'varnish_instance' |>
}
