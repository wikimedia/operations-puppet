class openstack::neutron::dhcp_agent::stein::buster(
) {
    require openstack::serverpackages::stein::buster

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
