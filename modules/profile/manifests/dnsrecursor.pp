# A profile class for a dns recursor

class profile::dnsrecursor (
  Optional[Hash[String, Wmflib::Advertise_vip]] $advertise_vips = lookup('profile::bird::advertise_vips', {'default_value' => {}})
  ) {
    include ::network::constants
    include ::profile::dns::ferm
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
}
