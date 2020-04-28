class openstack::neutron::dhcp_agent::rocky::buster(
) {
    require openstack::serverpackages::rocky::buster

    package { 'neutron-dhcp-agent':
        ensure => 'present',
    }
}
