# A profile class for a dns recursor

class profile::dns::recursor (
  Optional[Hash[String, Wmflib::Advertise_vip]] $advertise_vips = lookup('profile::bird::advertise_vips', {'default_value' => {}}),
  Optional[String] $bind_service = lookup('profile::dns::recursor::bind_service', {'default_value' => undef}),
  Optional[Stdlib::IP::Address::Nosubnet] $legacy_vip = lookup('profile::dns::recursor::legacy_vip', {'default_value' => undef}),
) {
    include ::network::constants
    include ::profile::base::firewall
    include ::profile::bird::anycast
    include ::profile::prometheus::pdns_rec_exporter

    # The $legacy_vip is to support the old lvs recdns IP in codfw and eqiad
    # temporarily, since there are a few trailing edge cases using it (a few
    # PDUs that are difficult to reconfigure, and an odd service daemon or two
    # that hasn't been restarted in a while).  Will be removed later!
    if $legacy_vip {
        interface::ip { 'lo-legacy-vip':
            ensure    => present,
            address   => $legacy_vip,
            interface => 'lo',
            options   => 'label lo:legacy',
            before    => Class['::dnsrecursor'],
        }
        $legacy_vips = [ $legacy_vip ]
    } else {
        $legacy_vips = []
    }

    $all_anycast_vips = $advertise_vips.map |$vip_fqdn,$vip_params| { $vip_params['address'] }

    $listen_addrs = [
        $facts['ipaddress'],
        $facts['ipaddress6'],
        $all_anycast_vips,
    ] + $legacy_vips

    class { '::dnsrecursor':
        version_hostname  => true,
        allow_from        => $network::constants::aggregate_networks,
        listen_addresses  => $listen_addrs,
        allow_from_listen => false,
        log_common_errors => 'no',
        threads           => $facts['physicalcorecount'],
        bind_service      => $bind_service,
    }

    ferm::service { 'udp_dns_recursor':
        proto   => 'udp',
        notrack => true,
        prio    => '07',
        port    => '53',
        drange  => "(${listen_addrs.join(' ')})",
        srange  => "(${network::constants::aggregate_networks.join(' ')})",
    }

    ferm::service { 'tcp_dns_recursor':
        proto   => 'tcp',
        notrack => true,
        prio    => '07',
        port    => '53',
        drange  => "(${listen_addrs.join(' ')})",
        srange  => "(${network::constants::aggregate_networks.join(' ')})",
    }

    ::dnsrecursor::monitor { [ $facts['ipaddress'], $facts['ipaddress6'] ]: }

    sudo::user { 'prometheus_sudo_for_pdns_recursor':
        user       => 'prometheus',
        privileges => ['ALL=(root) NOPASSWD: /usr/bin/rec_control get-all'],
    }
}
