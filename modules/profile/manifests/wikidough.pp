class profile::wikidough (
    Dnsdist::Resolver   $resolver   = lookup(profile::wikidough::resolver),
    Dnsdist::TLS_config $tls_config = lookup(profile::wikidough::tls::config),
) {

    include network::constants
    include passwords::dnsdist::wikidough

    ferm::service { 'wikidough-doh':
        proto  => 'tcp',
        port   => 443,
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'wikidough-dot':
        proto  => 'tcp',
        port   => 853,
        srange => '$PRODUCTION_NETWORKS',
    }

    acme_chief::cert { 'wikidough':
        puppet_svc => 'dnsdist',
        key_group  => '_dnsdist',
    }

    class { 'dnsdist':
        resolver       => $resolver,
        tls_config     => $tls_config,
        enable_console => true,
        console_key    => $passwords::dnsdist::wikidough::console_key,
    }

}
