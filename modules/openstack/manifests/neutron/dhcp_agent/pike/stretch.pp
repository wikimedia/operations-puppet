class openstack::neutron::dhcp_agent::pike::stretch(
) {
    require openstack::serverpackages::pike::stretch

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
