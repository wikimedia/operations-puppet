class openstack::neutron::service(
    $version,
    ) {

    package {'neutron-server':
        ensure => 'present',
    }

    class {'openstack::neutron::base':
        version => $version,
    }
    contain 'openstack::neutron::base'
}
