class openstack::neutron::l3_agent {

    package {'neutron-l3-agent':
        ensure => 'present',
    }
}
