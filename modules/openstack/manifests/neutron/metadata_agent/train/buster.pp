class openstack::neutron::metadata_agent::train::buster(
) {
    require ::openstack::serverpackages::train::buster

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
