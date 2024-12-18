# SPDX-License-Identifier: Apache-2.0
# Class: profile::openstack::pdns::recursor::service
#
# This class installs a pdns recursor for use by cloud-vps VMs.
#
# It also injects a simple 'puppet' hostname for bootstrapping
#  new VMs.

class profile::openstack::base::pdns::recursor::service(
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    $observer_user = lookup('profile::openstack::base::observer_user'),
    $observer_password = lookup('profile::openstack::base::observer_password'),
    $observer_project = lookup('profile::openstack::base::observer_project'),
    $legacy_tld = lookup('profile::openstack::base::pdns::legacy_tld'),
    $private_reverse_zones = lookup('profile::openstack::base::pdns::private_reverse_zones'),
    $extra_records = lookup('profile::openstack::base::pdns::recursor_extra_records'),
    Array[Stdlib::IP::Address] $extra_allow_from = lookup('profile::openstack::base::pdns::extra_allow_from', {default_value => []}),
    Array[Stdlib::IP::Address] $monitoring_hosts = lookup('monitoring_hosts', {default_value => []}),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::base::openstack_control_nodes',  {default_value => []}),
    Array[Stdlib::IP::Address] $pdns_api_allow_from = lookup('profile::openstack::base::pdns::pdns_api_allow_from', {'default_value' => []}),
    Optional[Stdlib::IP::Address::V4::Nosubnet] $bgp_vip = lookup('profile::openstack::base::pdns::recursor::bgp_vip', {'default_value' => undef}),
    Array[Hash]                $pdns_hosts       = lookup('profile::openstack::base::pdns::hosts'),
) {
    $this_host_entry = ($pdns_hosts.filter | $host | {$host['host_fqdn'] == $::fqdn})[0]
    $query_local_address = $this_host_entry['auth_fqdn']

    include ::network::constants
    $allow_from = flatten([
        $::network::constants::cloud_networks,
        $extra_allow_from,
        $monitoring_hosts,
        $openstack_control_nodes.map |OpenStack::ControlNode $node| {
            dnsquery::lookup($node['cloud_private_fqdn'], true)
        }.flatten
    ])

    file { '/var/zones':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444'
    }

    file { '/var/zones/labsdb':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/profile/openstack/base/pdns/recursor/labsdb.zone',
        notify  => Service['pdns-recursor'],
        require => File['/var/zones']
    }

    $pdns_auth_addrs = $pdns_hosts.map |$item| { dnsquery::lookup($item['auth_fqdn'], true) }.flatten.sort.join(';')
    $reverse_zone_rules = inline_template("<% @private_reverse_zones.each do |zone| %><%= zone %>=${pdns_auth_addrs}, <% end %>")

    class { '::dnsrecursor':
        listen_addresses         => [$bgp_vip],
        allow_from               => $allow_from,
        additional_forward_zones => "${legacy_tld}=${pdns_auth_addrs}, ${reverse_zone_rules}",
        auth_zones               => 'labsdb=/var/zones/labsdb',
        max_negative_ttl         => 30,
        max_tcp_per_client       => 10,
        max_cache_entries        => 3000000,
        client_tcp_timeout       => 1,
        dnssec                   => 'off',  # T226088 - off until 4.1.x
        enable_webserver         => debian::codename::ge('bullseye'),
        api_allow_from           => $pdns_api_allow_from,
        query_local_address      => dnsquery::lookup($query_local_address, true),
        threads                  => 12,
        extra_records            => $extra_records,
    }

    firewall::service { 'recursor_udp_dns_rec':
        proto  => 'udp',
        port   => 53,
        srange => $allow_from,
    }

    firewall::service { 'recursor_tcp_dns_rec':
        proto  => 'tcp',
        port   => 53,
        srange => $allow_from,
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
