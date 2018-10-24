class profile::openstack::main::pdns::recursor::service(
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    $keystone_host = hiera('profile::openstack::main::keystone_host'),
    $observer_password = hiera('profile::openstack::main::observer_password'),
    $pdns_host = hiera('profile::openstack::main::pdns::host'),
    $pdns_recursor = hiera('profile::openstack::main::pdns::recursor'),
    $tld = hiera('profile::openstack::main::pdns::tld'),
    $private_reverse_zones = hiera('profile::openstack::main::pdns::private_reverse_zones'),
    $aliaser_extra_records = hiera('profile::openstack::main::pdns::recursor_aliaser_extra_records'),
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

    class{'::profile::openstack::base::pdns::recursor::monitor::rec_control':}
}
