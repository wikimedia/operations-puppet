class openstack::neutron::l3_agent::victoria::buster(
) {
    require openstack::serverpackages::victoria::buster

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
