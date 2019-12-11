class profile::dns::auth::monitoring {
    # Metrics!
    class { 'prometheus::node_gdnsd': }

    # Monitor gdnsd checkconf via NRPE
    class { 'gdnsd::monitor_conf': }

    # This monitors the specific authdns server directly via
    #  its own fqdn, which won't generally be one of the listener
    #  addresses we really care about.  This gives a more-direct
    #  view of reality, though, as the mapping of listener addresses
    #  to real hosts could be fluid due to routing/anycast.
    monitoring::service { 'auth dns':
        description   => 'Auth DNS',
        check_command => 'check_dns_query_auth_port!5353!www.wikipedia.org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/DNS',
    }

    # Authdns needs additional rules beyond profile::dns::ferm, for its special
    # port 5353 monitoring listeners.  These can be tracked like normal since
    # they're not high volume.  Icinga hosts have special ferm access in
    # general, but humans will also sometimes want to hit these...
    ferm::service { 'udp_dns_auth_monitor':
        proto  => 'udp',
        port   => '5353',
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'tcp_dns_auth_monitor':
        proto  => 'tcp',
        port   => '5353',
        srange => '$PRODUCTION_NETWORKS',
    }
}
