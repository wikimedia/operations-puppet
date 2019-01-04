class openstack::neutron::metadata_agent::mitaka::stretch(
) {
    require ::openstack::serverpackages::mitaka::stretch

    package {'neutron-metadata-agent':
        ensure          => 'present',
        install_options => ['-t', 'jessie-backports'],
    }
}
