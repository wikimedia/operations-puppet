class openstack::neutron::metadata_agent::pike::stretch(
) {
    require ::openstack::serverpackages::pike::stretch

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
