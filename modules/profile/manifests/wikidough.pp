class profile::wikidough (
    Dnsdist::Resolver         $resolver         = lookup('profile::wikidough::dnsdist::resolver'),
    Dnsdist::TLS_common       $tls_common       = lookup('profile::wikidough::dnsdist::tls::common'),
    Dnsdist::TLS_config       $tls_config_doh   = lookup('profile::wikidough::dnsdist::tls::doh'),
    Dnsdist::TLS_config       $tls_config_dot   = lookup('profile::wikidough::dnsdist::tls::dot'),
    Dnsdist::Webserver_config $webserver_config = lookup('profile::wikidough::dnsdist::webserver', {'merge' => hash}),
    String                    $landing_text     = lookup('profile::wikidough::dnsdist::landing_text'),
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
        listen_addresses         => [$resolver['host']],
        allow_from               => ['127.0.0.0/8'],
        max_tcp_per_client       => 0,
        client_tcp_timeout       => 5,
        dnssec                   => 'validate',
        allow_forward_zones      => false,
        allow_incoming_ecs       => true,
        allow_qname_minimisation => true,
        install_from_component   => true,
    }

    acme_chief::cert { 'wikidough':
        puppet_svc => 'dnsdist',
        key_group  => '_dnsdist',
    }

    class { 'dnsdist':
        resolver         => $resolver,
        tls_common       => $tls_common,
        tls_config_doh   => $tls_config_doh,
        tls_config_dot   => $tls_config_dot,
        enable_console   => true,
        console_key      => $passwords::wikidough::dnsdist::console_key,
        enable_webserver => true,
        webserver        => $webserver_config,
        enable_landing   => true,
        landing_text     => $landing_text,
        require          => Class['dnsrecursor'],
    }

    monitoring::service { 'check_wikidough_doh':
        description   => 'Wikidough DoH Check',
        check_command => 'check_https_on_port!malmok.wikimedia.org!443',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Wikidough',
    }

    monitoring::service { 'check_wikidough_dot':
        description   => 'Wikidough DoT Check',
        check_command => 'check_tcp_ssl!208.80.153.43!853',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Wikidough',
    }

}
