class openstack::neutron::dhcp_agent::wallaby::bullseye(
) {
    require openstack::serverpackages::wallaby::bullseye

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
