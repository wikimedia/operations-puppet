class openstack::neutron::metadata_agent::queens::stretch(
) {
    require ::openstack::serverpackages::queens::stretch

    package {'neutron-metadata-agent':
        ensure => 'present',
    }
}
