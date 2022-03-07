class openstack::neutron::metadata_agent::wallaby::bullseye(
) {
    require ::openstack::serverpackages::wallaby::bullseye

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
