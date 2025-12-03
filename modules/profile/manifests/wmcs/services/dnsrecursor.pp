# SPDX-License-Identifier: Apache-2.0
# == Class profile::wmcs::services::dnsrecursor
#
# Simple VM-hosted dns recursor, backed by the wmcs
#  auth on cloudservices nodes
#
# This class doesn't seek to restrict who can
#  access the recursor; we'll leave that for
#  security groups to manage.
#
# Sample hiera config for this:
#
#profile::openstack::base::pdns::hosts:
#- auth_fqdn: ns0.openstack.eqiad1.wikimediacloud.org
  #host_fqdn: cloudservices1005.eqiad.wmnet
  #private_fqdn: cloudservices1005.private.eqiad.wikimedia.cloud
#- auth_fqdn: ns1.openstack.eqiad1.wikimediacloud.org
  #host_fqdn: cloudservices1006.eqiad.wmnet
  #private_fqdn: cloudservices1006.private.eqiad.wikimedia.cloud
#profile::openstack::base::pdns::legacy_tld: wmflabs
#profile::openstack::base::pdns::private_reverse_zones:
#- 16.172.in-addr.arpa
#
class profile::wmcs::services::dnsrecursor (
    String                     $legacy_tld = lookup('profile::openstack::base::pdns::legacy_tld'),
    Array[Profile::Openstack::Pdns::Host]                $pdns_hosts       = lookup('profile::openstack::base::pdns::hosts'),
    Array[String]              $private_reverse_zones = lookup('profile::openstack::base::pdns::private_reverse_zones'),
    Array[Stdlib::IP::Address] $monitoring_hosts = lookup('monitoring_hosts', {default_value => []}),
) {
    file { '/var/zones':
        ensure => directory
    }
    file { '/var/zones/labsdb':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/openstack/base/pdns/recursor/labsdb.zone',
        notify => Service['pdns-recursor'],
    }

    include ::network::constants
    $allow_from = flatten([
        $::network::constants::cloud_networks,
        $monitoring_hosts,
    ])

    $pdns_auth_addrs = $pdns_hosts.map |$item| { $item['auth_ips'] }.flatten.sort.join(';')
    $reverse_zone_rules = $private_reverse_zones.map |$zone| { "${zone}=${pdns_auth_addrs}" }.join(', ')

    class { '::dnsrecursor':
        listen_addresses         => ['0.0.0.0'],
        allow_from               => $allow_from,
        additional_forward_zones => "${legacy_tld}=${pdns_auth_addrs}, ${reverse_zone_rules}",
        auth_zones               => ['labsdb=/var/zones/labsdb'],
        max_negative_ttl         => 30,
        max_tcp_per_client       => 10,
        max_cache_entries        => 3000000,
        client_tcp_timeout       => 1,
        dnssec                   => 'off',  # T226088 - off until 4.1.x
        enable_webserver         => false,
        threads                  => 12,
    }
}
