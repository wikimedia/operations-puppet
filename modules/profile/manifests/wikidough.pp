class profile::wikidough (
    Dnsdist::Resolver         $resolver         = lookup(profile::wikidough::dnsdist::resolver),
    Dnsdist::TLS_config       $tls_config       = lookup(profile::wikidough::dnsdist::tls),
    Dnsdist::Webserver_config $webserver_config = lookup(profile::wikidough::dnsdist::webserver, {'merge' => hash}),
) {

    include network::constants
    include passwords::wikidough::dnsdist

    ferm::service { 'wikidough-doh':
        proto   => 'tcp',
        notrack => true,
        port    => 443,
    }

    ferm::service { 'wikidough-dot':
        proto   => 'tcp',
        notrack => true,
        port    => 853,
    }

    ferm::service { 'wikidough-dnsdist-webserver':
        proto  => 'tcp',
        port   => $webserver_config['port'],
        srange => '$PRODUCTION_NETWORKS',
    }

    class { 'dnsrecursor':
        listen_addresses     => [$resolver['host']],
        allow_from           => ['127.0.0.0/8'],
        allow_forward_zones  => false,
        allow_edns_whitelist => false,
    }

    acme_chief::cert { 'wikidough':
        puppet_svc => 'dnsdist',
        key_group  => '_dnsdist',
    }

    class { 'dnsdist':
        resolver         => $resolver,
        tls_config       => $tls_config,
        enable_console   => true,
        console_key      => $passwords::wikidough::dnsdist::console_key,
        enable_webserver => true,
        webserver_config => $webserver_config,
        require          => Class['dnsrecursor'],
    }

}
