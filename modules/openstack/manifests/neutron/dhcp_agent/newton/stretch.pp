class openstack::neutron::dhcp_agent::newton::stretch(
) {
    require openstack::serverpackages::newton::stretch

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
