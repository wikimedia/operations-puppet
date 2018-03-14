class openstack::neutron::service(
    $version,
    ) {

    package {'neutron-server':
        ensure => 'present',
    }
}
