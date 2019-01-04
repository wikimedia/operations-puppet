class openstack::neutron::metadata_agent::mitaka::jessie(
) {
    require ::openstack::serverpackages::mitaka::jessie

    package {'neutron-metadata-agent':
        ensure          => 'present',
        install_options => ['-t', 'jessie-backports'],
    }
}
