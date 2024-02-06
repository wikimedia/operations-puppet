class profile::openstack::eqiad1::pdns::recursor::service(
    Array[Hash]         $pdns_hosts      = lookup('profile::openstack::eqiad1::pdns::hosts'),
    Stdlib::Fqdn $keystone_api_fqdn      = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    $observer_password = lookup('profile::openstack::eqiad1::observer_password'),
    $legacy_tld = lookup('profile::openstack::eqiad1::pdns::legacy_tld'),
    $private_reverse_zones = lookup('profile::openstack::eqiad1::pdns::private_reverse_zones'),
    $aliaser_extra_records = lookup('profile::openstack::eqiad1::pdns::recursor_aliaser_extra_records'),
    Array[Stdlib::IP::Address] $extra_allow_from = lookup('profile::openstack::eqiad1::pdns::extra_allow_from', {default_value => []}),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::eqiad1::openstack_control_nodes'),
    Array[Stdlib::Fqdn] $prometheus_nodes = lookup('prometheus_nodes'),
) {
    # for now only prometheus metrics are needed.. maybe something else in the future?
    $api_allow_hosts = $prometheus_nodes

    class {'::profile::openstack::base::pdns::recursor::service':
        keystone_api_fqdn       => $keystone_api_fqdn,
        observer_password       => $observer_password,
        pdns_hosts              => $pdns_hosts,
        legacy_tld              => $legacy_tld,
        private_reverse_zones   => $private_reverse_zones,
        aliaser_extra_records   => $aliaser_extra_records,
        extra_allow_from        => $extra_allow_from,
        openstack_control_nodes => $openstack_control_nodes,
        pdns_api_allow_from     => flatten([
            '127.0.0.1',
            $api_allow_hosts.map |Stdlib::Fqdn $host| { ipresolve($host, 4) }
        ]),
    }
}
