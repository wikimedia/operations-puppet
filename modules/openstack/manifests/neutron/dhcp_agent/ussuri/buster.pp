class openstack::neutron::dhcp_agent::ussuri::buster(
) {
    require openstack::serverpackages::ussuri::buster

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
