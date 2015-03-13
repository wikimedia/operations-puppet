# role/dns.pp

class role::dns::ldap {
    include ldap::role::config::labs

    $ldapconfig = $ldap::role::config::labs::ldapconfig

    if $::site == 'eqiad' {
        interface::ip { 'role::dns::ldap':
            interface => 'eth0',
            address   => '208.80.154.19'
        }

        # FIXME: turn these settings into a hash that can be included somewhere
        class { 'dns::auth-server::ldap':
            dns_auth_ipaddress      => '208.80.154.19 208.80.154.18',
            dns_auth_query_address  => '208.80.154.19',
            dns_auth_soa_name       => 'labs-ns0.wikimedia.org',
            ldap_hosts              => $ldapconfig['servernames'],
            ldap_base_dn            => $ldapconfig['basedn'],
            ldap_user_dn            => $ldapconfig['proxyagent'],
            ldap_user_pass          => $ldapconfig['proxypass'],
        }
    }
    if $::site == 'codfw' {
        interface::ip { 'role::dns::ldap':
            interface => 'eth0',
            address   => '208.80.153.15'
        }

        # FIXME: turn these settings into a hash that can be included somewhere
        class { 'dns::auth-server::ldap':
            dns_auth_ipaddress      => '208.80.153.15 208.80.153.14',
            dns_auth_query_address  => '208.80.153.15',
            dns_auth_soa_name       => 'labs-ns1.wikimedia.org',
            ldap_hosts              => $ldapconfig['servernames'],
            ldap_base_dn            => $ldapconfig['basedn'],
            ldap_user_dn            => $ldapconfig['proxyagent'],
            ldap_user_pass          => $ldapconfig['proxypass'],
        }
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

class role::dnsrecursor {
    system::role { 'role::dnsrecursor': description => 'Recursive DNS server' }

    include lvs::configuration, network::constants

    class {
        'lvs::realserver':
            realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['dns_rec'][$::site];
        '::dnsrecursor':
            require             => Class['lvs::realserver'],
            listen_addresses    => [$::ipaddress,
                                    $::ipaddress6_eth0,
                                    $lvs::configuration::lvs_service_ips[$::realm]['dns_rec'][$::site],
                                  ],
            allow_from          => $network::constants::all_networks;
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
