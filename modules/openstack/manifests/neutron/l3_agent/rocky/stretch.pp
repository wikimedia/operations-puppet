class openstack::neutron::l3_agent::rocky::stretch(
) {
    require openstack::serverpackages::rocky::stretch

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
