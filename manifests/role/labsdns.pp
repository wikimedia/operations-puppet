class role::labsdns {
    system::role { 'role::labsdns': description => 'DNS server for Labs instances' }
    include passwords::pdns

    class { '::labs_dns':
        dns_auth_ipaddress     => '208.80.154.12',
        dns_auth_query_address => '208.80.154.12',
        dns_auth_soa_name      => 'labs-ns2.wikimedia.org',
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

# Class: role::labsdnsrecursor
#
# Labs instances can't communicate directly with other instances
#  via floating IP, but they often want to do DNS lookups for the
#  public IP of other instances (e.g. beta.wmflabs.org).
#
# This recursor does two useful things:
#
#  - It maintains a mapping between floating and private IPs
#  for select instances.  Anytime the upstream DNS server returns
#  a public IP in that mapping, we return the corresponding private
#  IP instead.
#
#  - It relays requests for *.wmflabs to the auth server that knows
#  about such things (defined as $labs_forward)
#
#  Other than that it should act like any other WMF recursor.
#
#
# Eventually all labs instances will point to one of these in resolv.conf

class role::labsdnsrecursor {

    $recursor_ip = ipresolve(hiera('labs_recursor'),4)

    interface::ip { 'role::labsdnsrecursor':
        interface => 'eth0',
        address   => $recursor_ip
    }

    system::role { 'role::labsdnsrecursor': description => 'Recursive DNS server for Labs instances' }

    #  We need to alias some public IPs to their corresponding private IPs.
    #   FIXME:  these should be automatically synced rather than hard-coded.
    $nova_floating_ip_aliases = {
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
        'labs'  => [$::ipaddress],
        default => [$recursor_ip]
    }

    $labs_auth_dns = ipresolve(hiera('labs_dns_host'),4)

    class { ::dnsrecursor:
            listen_addresses         => $listen_addresses,
            allow_from               => ['10.68.16.0/21'],
            ip_aliases               => $nova_floating_ip_aliases,
            additional_forward_zones => "wmflabs=${labs_auth_dns}"
    }

    ::dnsrecursor::monitor { $listen_addresses: }

    ferm::service { 'recursor_udp_dns_rec':
        proto => 'udp',
        port  => '53',
    }

    ferm::service { 'recursor_tcp_dns_rec':
        proto => 'tcp',
        port  => '53',
    }

    ferm::rule { 'recursor_skip_dns_conntrack-out':
        desc  => 'Skip DNS outgoing connection tracking',
        table => 'raw',
        chain => 'OUTPUT',
        rule  => 'proto udp sport 53 NOTRACK;',
    }

    ferm::rule { 'recursor_skip_dns_conntrack-in':
        desc  => 'Skip DNS incoming connection tracking',
        table => 'raw',
        chain => 'PREROUTING',
        rule  => 'proto udp dport 53 NOTRACK;',
    }
}
