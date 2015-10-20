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
            'text'   => 'beta.wmflabs.org,bits.beta.wmflabs.org,www.wikipedia.beta.wmflabs.org,www.wikimedia.beta.wmflabs.org,commons.wikipedia.beta.wmflabs.org,commons.wikimedia.beta.wmflabs.org,deployment.wikimedia.beta.wmflabs.org,en.wikibooks.beta.wmflabs.org,en.wikinews.beta.wmflabs.org,en.wikiquote.beta.wmflabs.org,en.wikisource.beta.wmflabs.org,en.wikiversity.beta.wmflabs.org,en.wikivoyage.beta.wmflabs.org,en.wiktionary.beta.wmflabs.org,login.wikimedia.beta.wmflabs.org,meta.wikimedia.beta.wmflabs.org,test.wikimedia.beta.wmflabs.org,wikidata.beta.wmflabs.org,zero.wikimedia.beta.wmflabs.org,aa.wikipedia.beta.wmflabs.org,ar.wikipedia.beta.wmflabs.org,ca.wikipedia.beta.wmflabs.org,de.wikipedia.beta.wmflabs.org,en-rtl.wikipedia.beta.wmflabs.org,en.wikipedia.beta.wmflabs.org,eo.wikipedia.beta.wmflabs.org,es.wikipedia.beta.wmflabs.org,fa.wikipedia.beta.wmflabs.org,he.wikipedia.beta.wmflabs.org,hi.wikipedia.beta.wmflabs.org,ja.wikipedia.beta.wmflabs.org,ko.wikipedia.beta.wmflabs.org,ru.wikipedia.beta.wmflabs.org,simple.wikipedia.beta.wmflabs.org,sq.wikipedia.beta.wmflabs.org,uk.wikipedia.beta.wmflabs.org,zh.wikipedia.beta.wmflabs.org,commons.m.wikimedia.beta.wmflabs.org,deployment.m.wikimedia.beta.wmflabs.org,en.m.wikibooks.beta.wmflabs.org,en.m.wikinews.beta.wmflabs.org,en.m.wikiquote.beta.wmflabs.org,en.m.wikisource.beta.wmflabs.org,en.m.wikiversity.beta.wmflabs.org,en.m.wikivoyage.beta.wmflabs.org,en.m.wiktionary.beta.wmflabs.org,login.m.wikimedia.beta.wmflabs.org,meta.m.wikimedia.beta.wmflabs.org,test.m.wikimedia.beta.wmflabs.org,m.wikidata.beta.wmflabs.org,zero.m.wikimedia.beta.wmflabs.org,aa.m.wikipedia.beta.wmflabs.org,ar.m.wikipedia.beta.wmflabs.org,ca.m.wikipedia.beta.wmflabs.org,de.m.wikipedia.beta.wmflabs.org,en-rtl.m.wikipedia.beta.wmflabs.org,en.m.wikipedia.beta.wmflabs.org,eo.m.wikipedia.beta.wmflabs.org,es.m.wikipedia.beta.wmflabs.org,fa.m.wikipedia.beta.wmflabs.org,he.m.wikipedia.beta.wmflabs.org,hi.m.wikipedia.beta.wmflabs.org,ja.m.wikipedia.beta.wmflabs.org,ko.m.wikipedia.beta.wmflabs.org,ru.m.wikipedia.beta.wmflabs.org,simple.m.wikipedia.beta.wmflabs.org,sq.m.wikipedia.beta.wmflabs.org,uk.m.wikipedia.beta.wmflabs.org,zh.m.wikipedia.beta.wmflabs.org,aa.zero.wikipedia.beta.wmflabs.org,ar.zero.wikipedia.beta.wmflabs.org,ca.zero.wikipedia.beta.wmflabs.org,de.zero.wikipedia.beta.wmflabs.org,en-rtl.zero.wikipedia.beta.wmflabs.org,en.zero.wikipedia.beta.wmflabs.org,eo.zero.wikipedia.beta.wmflabs.org,es.zero.wikipedia.beta.wmflabs.org,fa.zero.wikipedia.beta.wmflabs.org,he.zero.wikipedia.beta.wmflabs.org,hi.zero.wikipedia.beta.wmflabs.org,ja.zero.wikipedia.beta.wmflabs.org,ko.zero.wikipedia.beta.wmflabs.org,ru.zero.wikipedia.beta.wmflabs.org,simple.zero.wikipedia.beta.wmflabs.org,sq.zero.wikipedia.beta.wmflabs.org,uk.zero.wikipedia.beta.wmflabs.org,zh.zero.wikipedia.beta.wmflabs.org'
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
