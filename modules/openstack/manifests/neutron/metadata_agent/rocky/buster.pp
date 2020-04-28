class openstack::neutron::metadata_agent::rocky::buster(
) {
    require ::openstack::serverpackages::rocky::buster

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
