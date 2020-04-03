class openstack::neutron::metadata_agent::rocky::stretch(
) {
    require ::openstack::serverpackages::rocky::stretch

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
