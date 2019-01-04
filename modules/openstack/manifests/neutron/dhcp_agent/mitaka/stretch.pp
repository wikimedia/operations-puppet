class openstack::neutron::dhcp_agent::mitaka::stretch(
) {
    require openstack::serverpackages::mitaka::stretch

    package { 'neutron-dhcp-agent':
        ensure          => 'present',
        install_options => ['-t', 'jessie-backports']
    }
}
