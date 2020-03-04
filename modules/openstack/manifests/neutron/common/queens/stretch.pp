class openstack::neutron::common::queens::stretch(
) {
    require openstack::serverpackages::queens::stretch

    package { 'neutron-common':
        ensure => 'present',
    }
}
