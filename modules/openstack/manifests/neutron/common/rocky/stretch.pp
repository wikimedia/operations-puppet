class openstack::neutron::common::rocky::stretch(
) {
    require openstack::serverpackages::rocky::stretch

    package { 'neutron-common':
        ensure => 'present',
    }
}
