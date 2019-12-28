class openstack::neutron::common::pike::stretch(
) {
    require openstack::serverpackages::pike::stretch

    package { 'neutron-common':
        ensure => 'present',
    }
}
