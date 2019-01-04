class openstack::neutron::l3_agent::mitaka::stretch(
) {
    require openstack::serverpackages::mitaka::stretch

    package { 'neutron-l3-agent':
        ensure          => 'present',
        install_options => ['-t', 'jessie-backports'],
    }
}
