class openstack::neutron::metadata_agent::victoria::buster(
) {
    require ::openstack::serverpackages::victoria::buster

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
