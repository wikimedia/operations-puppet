# SPDX-License-Identifier: Apache-2.0
# A profile class for a DNS recursor

class profile::dns::recursor (
    Optional[Hash[String, Wmflib::Advertise_vip]]     $advertise_vips           = lookup('profile::bird::advertise_vips', {'default_value' => {}, 'merge' => hash}),
    Optional[String]                                  $bind_service             = lookup('profile::dns::recursor::bind_service', {'default_value' => undef}),
    Hash[Wmflib::Sites, Array[Stdlib::Fqdn]]          $ntp_peers                = lookup('ntp_peers'),
    Hash[Wmflib::Sites, Wmflib::Sites]                $site_nearest_core        = lookup('site_nearest_core'),
    Hash[Stdlib::Fqdn, Stdlib::IP::Address::Nosubnet] $authdns_servers          = lookup('authdns_servers'),
    Array[Stdlib::IP::Address]                        $dont_query               = lookup('profile::dns::recursor::dont_query', {'default_value' => []}),
    Array[Stdlib::IP::Address]                        $dont_query_negations     = lookup('profile::dns::recursor::dont_query_negations', {'default_value' => []}),
) {
    include network::constants
    include profile::firewall
    include profile::bird::anycast
    include profile::dns::check_dns_query

    # For historical context, this was managed through per-host DNS host
    # overrides, such as hieradata/hosts/dns1001.yaml. To manage this list
    # manually, we do not include profile::resolving from profile::base but
    # instead call it from here, passing the automatically generated
    # resolv.conf nameservers list.
    #
    # This is a bit of a hack: since all NTP hosts are also DNS hosts, use the
    # ntp_peers list to get a list of per-site DNS hosts. We use the same logic
    # to generate the NTP peers list in P:systemd::timesyncd, with the
    # difference that we need the IP addresses here and not the hostnames.
    $dns_servers_and_self = [$ntp_peers[$::site], $ntp_peers[$site_nearest_core[$::site]]].flatten

    # A host cannot/should not resolve against itself.
    $dns_servers = delete($dns_servers_and_self, $facts['networking']['fqdn'])

    # Get the IP addresses from authdns_servers in common.yaml, since it's the
    # canonical list anyway.
    $nameservers = $dns_servers.map |$server| {
        $authdns_servers[$server]
    }.filter |$x| { $x =~ NotUndef }

    if $nameservers.empty() {
        fail('no nameservers configured')
    }
    class { 'profile::resolving' :
        nameservers => $nameservers,
    }

    $recdns_vips = $advertise_vips.filter |$vip_fqdn,$vip_params| { $vip_params['service_type'] == 'recdns' }
    $recdns_addrs = $recdns_vips.map |$vip_fqdn,$vip_params| { $vip_params['address'] }

    $listen_addrs = [
        $facts['ipaddress'],
        $facts['ipaddress6'],
        $recdns_addrs,
    ]

    class { '::dnsrecursor':
        version_hostname      => true,
        allow_from            => $network::constants::aggregate_networks,
        listen_addresses      => $listen_addrs,
        allow_from_listen     => false,
        log_common_errors     => 'no',
        threads               => $facts['physicalcorecount'],
        enable_webserver      => debian::codename::ge('bullseye'),
        webserver_port        => 9199,
        api_allow_from        => $network::constants::aggregate_networks,
        bind_service          => $bind_service,
        allow_extended_errors => true,
        require               => Systemd::Service['gdnsd'],
        dont_query            => $dont_query,
        dont_query_negations  => $dont_query_negations,
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
