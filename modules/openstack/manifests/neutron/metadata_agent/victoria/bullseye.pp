class openstack::neutron::metadata_agent::victoria::bullseye(
) {
    require ::openstack::serverpackages::victoria::bullseye

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
