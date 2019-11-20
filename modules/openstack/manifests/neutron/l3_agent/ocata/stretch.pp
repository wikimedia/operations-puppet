class openstack::neutron::l3_agent::ocata::stretch(
) {
    require openstack::serverpackages::ocata::stretch

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
