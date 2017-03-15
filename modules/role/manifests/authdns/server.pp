# This is for an authdns server to use
class role::authdns::server {
    system::role { 'authdns': description => 'Authoritative DNS server' }

    include ::base::firewall
    include authdns::ganglia
    include prometheus::node_gdnsd
    include role::authdns::data

    create_resources(
        interface::ip,
        $role::authdns::data::ns_addrs,
        { interface => 'lo' }
    )

    class { 'authdns':
        nameservers        => $role::authdns::data::nameservers,
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

    $authdns_ns_ferm = join($role::authdns::data::nameservers, ' ')
    ferm::service { 'authdns_update_ssh':
        proto  => 'tcp',
        port   => '22',
        srange => "(@resolve((${authdns_ns_ferm})) @resolve((${authdns_ns_ferm}), AAAA))",
    }
}
