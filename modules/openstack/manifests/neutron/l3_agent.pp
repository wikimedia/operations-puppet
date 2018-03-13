class openstack::neutron::l3_agent {

    class {'openstack::neutron::base':}

    package {'neutron-l3-agent':
        ensure => 'present',
    }
}
