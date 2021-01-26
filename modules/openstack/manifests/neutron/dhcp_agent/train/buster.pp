class openstack::neutron::dhcp_agent::train::buster(
) {
    require openstack::serverpackages::train::buster

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
