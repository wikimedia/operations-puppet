class openstack::neutron::l3_agent::rocky::buster(
) {
    require openstack::serverpackages::rocky::buster

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
