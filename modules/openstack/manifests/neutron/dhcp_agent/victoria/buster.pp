class openstack::neutron::dhcp_agent::victoria::buster(
) {
    require openstack::serverpackages::victoria::buster

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
