class openstack::neutron::l3_agent::mitaka::jessie(
) {
    require openstack::serverpackages::mitaka::jessie

    package { 'neutron-l3-agent':
        ensure          => 'present',
        install_options => ['-t', 'jessie-backports'],
    }
}
