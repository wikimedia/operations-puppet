class profile::openstack::eqiad1::pdns::recursor::service(
    $nova_controller = hiera('profile::openstack::eqiad1::nova_controller'),
    $keystone_host = hiera('profile::openstack::eqiad1::keystone_host'),
    $observer_password = hiera('profile::openstack::eqiad1::observer_password'),
    $pdns_host = hiera('profile::openstack::eqiad1::pdns::host'),
    $pdns_recursor = hiera('profile::openstack::eqiad1::pdns::recursor'),
    $tld = hiera('profile::openstack::eqiad1::pdns::tld'),
    $private_reverse_zones = hiera('profile::openstack::eqiad1::pdns::private_reverse_zones'),
    $aliaser_extra_records = hiera('profile::openstack::eqiad1::pdns::recursor_aliaser_extra_records'),
    $use_metal_resolver = hiera('profile::openstack::eqiad1::pdns::use_metal_resolver'),
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
        use_metal_resolver    => $use_metal_resolver,
    }

    class{'::profile::openstack::base::pdns::recursor::monitor::rec_control':}
}
