class role::labsdns {
    system::role { 'role::labsdns': description => 'DNS server for Labs instances' }
    include passwords::pdns

    class { '::labs_dns':
        dns_auth_ipaddress     => '208.80.154.12',
        dns_auth_query_address => '208.80.154.12',
        dns_auth_soa_name      => 'labs-ns2.wikimedia.org',
        pdns_db_host           => 'm1-master.eqiad.wmnet',
        pdns_db_password       => $passwords::pdns::db_pass,
        pdns_recursor          => '208.80.154.239',
        recursor_ip_range      => '10.68.16.0/21',
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

class role::labsdnsrecursor {
    system::role { 'role::labsdnsrecursor': description => 'Recursive DNS server for Labs instances' }

    $nova_dnsmasq_aliases = {
        # eqiad
        'deployment-cache-text02'   => {public_ip  => '208.80.155.135',
                                        private_ip => '10.68.16.16' },
        'deployment-cache-upload02' => {public_ip  => '208.80.155.136',
                                        private_ip => '10.68.17.51' },
        'deployment-cache-bits01'   => {public_ip  => '208.80.155.137',
                                        private_ip => '10.68.16.12' },
        'deployment-stream'         => {public_ip  => '208.80.155.138',
                                        private_ip => '10.68.17.106' },
        'deployment-cache-mobile03' => {public_ip  => '208.80.155.139',
                                        private_ip => '10.68.16.13' },
        'relic'                     => {public_ip  => '208.80.155.197',
                                        private_ip => '10.68.16.162' },
        'tools-webproxy'            => {public_ip  => '208.80.155.131',
                                        private_ip => '10.68.17.139' },
        'udplog'                    => {public_ip  => '208.80.155.191',
                                        private_ip => '10.68.16.58' },

        # A wide variety of hosts are reachable via a public web proxy.
        'labs_shared_proxy' => {public_ip  => '208.80.155.156',
                                private_ip => '10.68.16.65'},
    }

    $listen_addresses = $::realm ? {
        'labs' => [$::ipaddress],
        default => [$::ipaddress, $::ipaddress6_eth0]
    }

    class { ::dnsrecursor:
            listen_addresses    => $listen_addresses,
            allow_from          => ['10.68.16.0/21'],
            ip_aliases          => $nova_dnsmasq_aliases,
            labs_forward        => '208.80.154.12'
    }

    ::dnsrecursor::monitor { [ $::ipaddress, $::ipaddress6_eth0 ]: }

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
