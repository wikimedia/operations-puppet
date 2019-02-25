# This is for an authdns server to use
class role::authdns::server {
    system::role { 'authdns': description => 'Authoritative DNS server' }

    include ::standard
    include ::profile::base::firewall
    include prometheus::node_gdnsd
    include role::authdns::data
    include ::profile::authdns::acmechief_target

    create_resources(
        interface::ip,
        $role::authdns::data::ns_addrs,
        { interface => 'lo' }
    )

    $authdns_servers = hiera('authdns_servers')

    class { 'authdns':
        nameservers        => $authdns_servers,
        gitrepo            => $role::authdns::data::gitrepo,
        lvs_services       => hiera('lvs::configuration::lvs_services'),
        discovery_services => hiera('discovery::services'),
    }

    ferm::service { 'udp_dns_auth':
        proto   => 'udp',
        notrack => true,
        port    => '53',
    }

    ferm::service { 'tcp_dns_auth':
        proto => 'tcp',
        port  => '53',
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
