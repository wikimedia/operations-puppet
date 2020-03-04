class openstack::neutron::l3_agent::queens::stretch(
) {
    require openstack::serverpackages::queens::stretch

    package { 'neutron-l3-agent':
        ensure => 'present',
    }
}
