class openstack::neutron::service {

    package {'neutron-server':
        ensure => 'present',
    }
}
