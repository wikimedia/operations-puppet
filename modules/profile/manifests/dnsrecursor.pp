# A profile class for a dns recursor

class profile::dnsrecursor {
    include ::network::constants
    include ::profile::base::firewall
    include ::lvs::configuration

    class { '::dnsrecursor':
        allow_from       => $network::constants::all_networks,
        listen_addresses => [
            $facts['ipaddress'],
            $facts['ipaddress6'],
            $lvs::configuration::service_ips['dns_rec'][$::site],
        ],
    }

    ::dnsrecursor::monitor { [ $facts['ipaddress'], $facts['ipaddress6'] ]: }

    ::diamond::collector { 'PowerDNSRecursor':
        ensure   => present,
        source   => 'puppet:///modules/diamond/collector/powerdns_recursor.py',
        settings => {
            # lint:ignore:quoted_booleans
            use_sudo => 'true',
            # lint:endignore
        },
        require  => Sudo::User['diamond_sudo_for_pdns_recursor'],
    }
    sudo::user { 'diamond_sudo_for_pdns_recursor':
        user       => 'diamond',
        privileges => ['ALL=(root) NOPASSWD: /usr/bin/rec_control get-all'],
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
