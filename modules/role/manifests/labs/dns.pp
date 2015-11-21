class role::labsdns {
    system::role { 'role::labs::dns':
        description => 'DNS server for Labs instances',
    }
    include passwords::pdns

    class { '::labs_dns':
        dns_auth_ipaddress     => $::ipaddress_eth0,
        dns_auth_query_address => $::ipaddress_eth0,
        dns_auth_soa_name      => hiera('labs_dns_host'),
        pdns_db_host           => 'm5-master.eqiad.wmnet',
        pdns_db_password       => $passwords::pdns::db_pass,
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
