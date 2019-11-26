class profile::dns::auth (
    Hash $lvs_services = lookup('lvs::configuration::lvs_services'),
    Hash $discovery_services = lookup('discovery::services'),
    Hash[String, Hash[String, String]] $authdns_addrs = lookup('authdns_addrs'),
    Array[String] $authdns_servers = lookup('authdns_servers'),
    Stdlib::HTTPSUrl $gitrepo = lookup('profile::dns::auth::gitrepo'),
    Boolean $mon_host53 = lookup('profile::dns::auth::mon_host53', {default_value => false}),
    $conftool_prefix = lookup('conftool_prefix'),
) {
    include ::profile::dns::auth::acmechief_target
    include ::profile::dns::ferm

    # Authdns needs additional rules beyond profile::dns::ferm, for its special
    # port 5353 monitoring listeners.  These can be tracked like normal since
    # they're not high volume.  Icinga hosts have special ferm access in
    # general, but humans will also sometimes want to hit these...
    ferm::service { 'udp_dns_auth_monitor':
        proto => 'udp',
        port  => '5353',
    }

    ferm::service { 'tcp_dns_auth_monitor':
        proto => 'tcp',
        port  => '5353',
    }

    class { 'prometheus::node_gdnsd': }

    create_resources(
        interface::ip,
        $authdns_addrs,
        { interface => 'lo', prefixlen => '32' }
    )

    $service_listeners = $authdns_addrs.map |$aspec| { $aspec[1]['address'] }

    # Port 53 monitoring on the host-level IPs, for legacy for now
    $host53_array = $mon_host53 ? {
        true    => [$::ipaddress, $::ipaddress6],
        default => [],
    }

    $monitor_listeners = $host53_array + [
        # Any-address, both protocols, port 5353, for blended-role monitoring
        '0.0.0.0:5353',
        '[::]:5353',
    ]

    class { 'authdns':
        nameservers        => $authdns_servers,
        gitrepo            => $gitrepo,
        lvs_services       => $lvs_services,
        discovery_services => $discovery_services,
        conftool_prefix    => $conftool_prefix,
        service_listeners  => $service_listeners,
        monitor_listeners  => $monitor_listeners,
    }

    $authdns_ns_ferm = join($authdns_servers, ' ')
    ferm::service { 'authdns_update_ssh':
        proto  => 'tcp',
        port   => '22',
        srange => "(@resolve((${authdns_ns_ferm})) @resolve((${authdns_ns_ferm}), AAAA))",
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
