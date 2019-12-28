class openstack::neutron::l3_agent::pike::stretch(
) {
    require openstack::serverpackages::pike::stretch

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
