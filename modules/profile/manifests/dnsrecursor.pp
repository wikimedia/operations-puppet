# A profile class for a dns recursor

class profile::dnsrecursor (
  Optional[Hash[String, Wmflib::Advertise_vip]] $advertise_vips = lookup('profile::bird::advertise_vips', {'default_value' => {}})
  ) {
    include ::network::constants
    include ::profile::base::firewall
    include ::lvs::configuration

    $all_anycast_vips = $advertise_vips.map |$vip_fqdn,$vip_params| { $vip_params['address'] }

    class { '::dnsrecursor':
        version_hostname => true,
        allow_from       => $network::constants::aggregate_networks,
        listen_addresses => [
            $facts['ipaddress'],
            $facts['ipaddress6'],
            $lvs::configuration::service_ips['dns_rec'][$::site],
            $all_anycast_vips,
        ],
    }

    ::dnsrecursor::monitor { [ $facts['ipaddress'], $facts['ipaddress6'] ]: }

    sudo::user { 'prometheus_sudo_for_pdns_recursor':
        user       => 'prometheus',
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
