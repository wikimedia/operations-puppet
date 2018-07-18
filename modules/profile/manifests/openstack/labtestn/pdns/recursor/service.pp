class profile::openstack::labtestn::pdns::recursor::service(
    $nova_controller = hiera('profile::openstack::labtestn::nova_controller'),
    $keystone_host = hiera('profile::openstack::labtestn::keystone_host'),
    $observer_password = hiera('profile::openstack::labtestn::observer_password'),
    $pdns_host = hiera('profile::openstack::labtestn::pdns::host'),
    $pdns_recursor = hiera('profile::openstack::labtestn::pdns::recursor'),
    $tld = hiera('profile::openstack::labtestn::pdns::tld'),
    $private_reverse = hiera('profile::openstack::labtestn::pdns::private_reverse'),
    $aliaser_extra_records = hiera('profile::openstack::labtestn::pdns::recursor_aliaser_extra_records'),
    ) {

    class {'::profile::openstack::base::pdns::recursor::service':
        nova_controller       => $nova_controller,
        keystone_host         => $keystone_host,
        observer_password     => $observer_password,
        pdns_host             => $pdns_host,
        pdns_recursor         => $pdns_recursor,
        tld                   => $tld,
        private_reverse       => $private_reverse,
        aliaser_extra_records => $aliaser_extra_records,
    }
}
