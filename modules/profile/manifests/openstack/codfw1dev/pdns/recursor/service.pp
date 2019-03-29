class profile::openstack::codfw1dev::pdns::recursor::service(
    $nova_controller = hiera('profile::openstack::codfw1dev::nova_controller'),
    $keystone_host = hiera('profile::openstack::codfw1dev::keystone_host'),
    $observer_password = hiera('profile::openstack::codfw1dev::observer_password'),
    $pdns_host = hiera('profile::openstack::codfw1dev::pdns::host'),
    $pdns_recursor = hiera('profile::openstack::codfw1dev::pdns::recursor'),
    $tld = hiera('profile::openstack::codfw1dev::pdns::tld'),
    $private_reverse_zones = hiera('profile::openstack::codfw1dev::pdns::private_reverse_zones'),
    $aliaser_extra_records = hiera('profile::openstack::codfw1dev::pdns::recursor_aliaser_extra_records'),
    ) {

    class {'::profile::openstack::base::pdns::recursor::service':
        nova_controller       => $nova_controller,
        keystone_host         => $keystone_host,
        observer_password     => $observer_password,
        pdns_host             => $pdns_host,
        pdns_recursor         => $pdns_recursor,
        tld                   => $tld,
        private_reverse_zones => $private_reverse_zones,
        aliaser_extra_records => $aliaser_extra_records,
    }
}
