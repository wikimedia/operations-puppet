class openstack::neutron::l3_agent::train::buster(
) {
    require openstack::serverpackages::train::buster

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
