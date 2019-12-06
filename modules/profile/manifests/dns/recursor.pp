# A profile class for a dns recursor

class profile::dns::recursor (
  Optional[Hash[String, Wmflib::Advertise_vip]] $advertise_vips = lookup('profile::bird::advertise_vips', {'default_value' => {}}),
  Optional[String] $bind_service = lookup('profile::dns::recursor::bind_service', {'default_value' => undef}),
) {
    include ::network::constants
    include ::profile::dns::ferm
    include ::profile::bird::anycast
    include ::profile::prometheus::pdns_rec_exporter

    class { '::lvs::realserver': } # Temporary, to unconfigure previous address

    $all_anycast_vips = $advertise_vips.map |$vip_fqdn,$vip_params| { $vip_params['address'] }

    class { '::dnsrecursor':
        version_hostname  => true,
        allow_from        => $network::constants::aggregate_networks,
        listen_addresses  => [
            $facts['ipaddress'],
            $facts['ipaddress6'],
            $all_anycast_vips,
        ],
        allow_from_listen => false,
        log_common_errors => 'no',
        threads           => $facts['physicalcorecount'],
        bind_service      => $bind_service,
    }

    ::dnsrecursor::monitor { [ $facts['ipaddress'], $facts['ipaddress6'] ]: }

    sudo::user { 'prometheus_sudo_for_pdns_recursor':
        user       => 'prometheus',
        privileges => ['ALL=(root) NOPASSWD: /usr/bin/rec_control get-all'],
    }
}
