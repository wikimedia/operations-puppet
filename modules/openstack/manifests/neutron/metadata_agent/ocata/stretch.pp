class openstack::neutron::metadata_agent::ocata::stretch(
) {
    require ::openstack::serverpackages::ocata::stretch

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
