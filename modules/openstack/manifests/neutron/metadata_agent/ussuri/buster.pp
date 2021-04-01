class openstack::neutron::metadata_agent::ussuri::buster(
) {
    require ::openstack::serverpackages::ussuri::buster

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
