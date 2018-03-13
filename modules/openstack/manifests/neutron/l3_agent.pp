class openstack::neutron::l3_agent(
    $version,
    ) {

    class {'openstack::neutron::base':
        version => $version,
    }
    contain 'openstack::neutron::base'

    package {'neutron-l3-agent':
        ensure => 'present',
    }
}
