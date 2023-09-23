# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::pdns::recursor::service(
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    $observer_password = lookup('profile::openstack::codfw1dev::observer_password'),
    Array[Stdlib::Fqdn] $pdns_hosts = lookup('profile::openstack::codfw1dev::pdns::hosts'),
    $legacy_tld = lookup('profile::openstack::codfw1dev::pdns::legacy_tld'),
    $private_reverse_zones = lookup('profile::openstack::codfw1dev::pdns::private_reverse_zones'),
    $aliaser_extra_records = lookup('profile::openstack::codfw1dev::pdns::recursor_aliaser_extra_records'),
    Array[Stdlib::IP::Address] $extra_allow_from = lookup('profile::openstack::codfw1dev::pdns::extra_allow_from', {default_value => []}),
    Array[Stdlib::Fqdn]        $controllers      = lookup('profile::openstack::codfw1dev::openstack_controllers',  {default_value => []}),
    Array[Stdlib::Fqdn] $prometheus_nodes = lookup('prometheus_nodes'),
) {
    # for now only prometheus metrics are needed.. maybe something else in the future?
    $api_allow_hosts = $prometheus_nodes

    class {'::profile::openstack::base::pdns::recursor::service':
        keystone_api_fqdn     => $keystone_api_fqdn,
        observer_password     => $observer_password,
        pdns_hosts            => $pdns_hosts,
        legacy_tld            => $legacy_tld,
        private_reverse_zones => $private_reverse_zones,
        aliaser_extra_records => $aliaser_extra_records,
        extra_allow_from      => $extra_allow_from,
        controllers           => $controllers,
        pdns_api_allow_from   => flatten([
            '127.0.0.1',
            $api_allow_hosts.map |Stdlib::Fqdn $host| { ipresolve($host, 4) }
        ]),
    }
}
