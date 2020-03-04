class openstack::neutron::dhcp_agent::queens::stretch(
) {
    require openstack::serverpackages::queens::stretch

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
