class openstack::neutron::l3_agent::newton::stretch(
) {
    require openstack::serverpackages::newton::stretch

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
