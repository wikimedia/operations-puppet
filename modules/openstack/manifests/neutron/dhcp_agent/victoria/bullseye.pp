class openstack::neutron::dhcp_agent::victoria::bullseye(
) {
    require openstack::serverpackages::victoria::bullseye

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
