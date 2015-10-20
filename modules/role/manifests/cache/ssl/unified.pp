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
        if hiera('cache::cluster') == 'upload' {
            $server_name = 'upload.beta.wmflabs.org'
            $subjects = ['upload.beta.wmflabs.org']
        } else {
            $server_name = 'beta.wmflabs.org'
            $subjects = cache_ssl_beta_subjects()
        }

        tlsproxy::localssl { 'unified':
            server_name    => $server_name,
            acme_subjects  => $subjects,
            default_server => true,
            do_ocsp        => false,
            skip_private   => true,
            upstream_port  => 3127,
            redir_port     => 8080,
        }
    }

    # ordering ensures nginx/varnish config/service-start are
    #  not intermingled during initial install where they could
    #  have temporary conflicts on binding port 80
    Service['nginx'] -> Service<| tag == 'varnish_instance' |>
}
