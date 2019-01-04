class openstack::neutron::dhcp_agent::mitaka::jessie(
) {
    require openstack::serverpackages::mitaka::jessie

    package { 'neutron-dhcp-agent':
        ensure          => 'present',
        install_options => ['-t', 'jessie-backports']
    }
}
