class openstack::neutron::metadata_agent::newton::stretch(
) {
    require ::openstack::serverpackages::newton::stretch

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
