class profile::openstack::base::pdns::auth::service(
    $host = hiera('profile::openstack::base::pdns::host'),
    $host_secondary = hiera('profile::openstack::base::pdns::host_secondary'),
    $target_fqdn = hiera('profile::openstack::base::pdns::target_fqdn'),
    $db_host = hiera('profile::openstack::base::pdns::db_host'),
    $db_pass = hiera('profile::openstack::base::pdns::db_pass'),
    ) {

    $host_ip = ipresolve($host,4)
    $host_secondary_ip = ipresolve($host_secondary,4)

    #    dns_auth_ipaddress     => $facts['ipaddress'],
    #    dns_auth_query_address => $facts['ipaddress'],
    class { '::pdns_server':
        dns_auth_ipaddress     => $::ipaddress,
        dns_auth_query_address => $::ipaddress,
        dns_auth_soa_name      => $host,
        pdns_db_host           => $db_host,
        pdns_db_password       => $db_pass,
    }

    ferm::service { 'udp_dns_rec':
        proto => 'udp',
        port  => '53',
    }

    ferm::service { 'tcp_dns_rec':
        proto => 'tcp',
        port  => '53',
    }

    ferm::rule { 'skip_dns_conntrack-out':
        desc  => 'Skip DNS outgoing connection tracking',
        table => 'raw',
        chain => 'OUTPUT',
        rule  => 'proto udp sport 53 NOTRACK;',
    }

    ferm::rule { 'skip_dns_conntrack-in':
        desc  => 'Skip DNS incoming connection tracking',
        table => 'raw',
        chain => 'PREROUTING',
        rule  => 'proto udp dport 53 NOTRACK;',
    }
}
