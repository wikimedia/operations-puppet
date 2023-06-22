# SPDX-License-Identifier: Apache-2.0
# A profile class for a dns recursor

class profile::dns::recursor (
  Optional[Hash[String, Wmflib::Advertise_vip]] $advertise_vips = lookup('profile::bird::advertise_vips', {'default_value' => {}}),
  Optional[String]                              $bind_service   = lookup('profile::dns::recursor::bind_service', {'default_value' => undef}),
) {
    include network::constants
    include profile::firewall
    include profile::bird::anycast
    include profile::dns::check_dns_query

    $recdns_vips = $advertise_vips.filter |$vip_fqdn,$vip_params| { $vip_params['service_type'] == 'recdns' }
    $recdns_addrs = $recdns_vips.map |$vip_fqdn,$vip_params| { $vip_params['address'] }

    $listen_addrs = [
        $facts['ipaddress'],
        $facts['ipaddress6'],
        $recdns_addrs,
    ]

    class { '::dnsrecursor':
        version_hostname  => true,
        allow_from        => $network::constants::aggregate_networks,
        listen_addresses  => $listen_addrs,
        allow_from_listen => false,
        log_common_errors => 'no',
        threads           => $facts['physicalcorecount'],
        enable_webserver  => debian::codename::ge('bullseye'),
        webserver_port    => 9199,
        api_allow_from    => $network::constants::aggregate_networks,
        bind_service      => $bind_service,
        require           => Systemd::Service['gdnsd'],
    }

    ferm::service { 'udp_dns_recursor':
        proto   => 'udp',
        notrack => true,
        prio    => 7,
        port    => '53',
        drange  => "(${listen_addrs.join(' ')})",
        srange  => "(${network::constants::aggregate_networks.join(' ')})",
    }

    ferm::service { 'tcp_dns_recursor':
        proto   => 'tcp',
        notrack => true,
        prio    => 7,
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
