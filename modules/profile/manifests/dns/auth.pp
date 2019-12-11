class profile::dns::auth (
    Hash[String, Hash[String, String]] $authdns_addrs = lookup('authdns_addrs'),
    Hash[Stdlib::Fqdn, Stdlib::IP::Address::Nosubnet] $authdns_servers = lookup('authdns_servers'),
    Stdlib::HTTPSUrl $gitrepo = lookup('profile::dns::auth::gitrepo'),
) {
    include ::profile::dns::auth::acmechief_target
    include ::profile::dns::ferm
    include ::profile::dns::auth::discovery

    # Monitor gdnsd checkconf via NRPE
    class { 'authdns::monitor_conf': }

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

    class { 'prometheus::node_gdnsd': }

    create_resources(
        interface::ip,
        $authdns_addrs,
        { interface => 'lo', prefixlen => '32' }
    )

    $service_listeners = $authdns_addrs.map |$aspec| { $aspec[1]['address'] }

    $monitor_listeners = [
        # Any-address, both protocols, port 5353, for blended-role monitoring
        '0.0.0.0:5353',
        '[::]:5353',
    ]

    class { 'authdns':
        authdns_servers   => $authdns_servers,
        gitrepo           => $gitrepo,
        service_listeners => $service_listeners,
        monitor_listeners => $monitor_listeners,
    }

    # Create explicit /etc/hosts entries for all authdns IPv4 to reach each
    # other by-hostname without working recdns
    create_resources('host', $authdns_servers.reduce({}) |$data,$kv| {
        $data + { $kv[0] => {
            ip => $kv[1],
            host_aliases => split($kv[0], '[.]')[0]
        }}
    })

    # Hardcode the same IPv4 addrs as above in the inter-authdns ferm rules for
    # ssh access as well
    ferm::service { 'authdns_update_ssh':
        proto  => 'tcp',
        port   => '22',
        srange => "(${authdns_servers.values().join(' ')})",
    }

    # Enable TFO, which gdnsd-3.x supports by default if enabled
    sysctl::parameters { 'TCP Fast Open for AuthDNS':
        values => {
            'net.ipv4.tcp_fastopen' => 3,
        },
    }

    # Enable RPS/RSS stuff.  Current authdns hosts have tg3 or bnx2 1G cards,
    # but it still helps!
    interface::rps { 'primary':
        interface => $facts['interface_primary'],
    }
}
