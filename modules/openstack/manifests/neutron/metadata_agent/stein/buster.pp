class openstack::neutron::metadata_agent::stein::buster(
) {
    require ::openstack::serverpackages::stein::buster

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
