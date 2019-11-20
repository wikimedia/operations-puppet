class openstack::neutron::dhcp_agent::ocata::stretch(
) {
    require openstack::serverpackages::ocata::stretch

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
