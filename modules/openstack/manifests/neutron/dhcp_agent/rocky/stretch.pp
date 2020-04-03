class openstack::neutron::dhcp_agent::rocky::stretch(
) {
    require openstack::serverpackages::rocky::stretch

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
