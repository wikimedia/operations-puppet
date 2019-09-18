class openstack::neutron::common::newton::stretch(
) {
    require openstack::serverpackages::newton::stretch

    package { 'neutron-common':
        ensure => 'present',
    }
}
