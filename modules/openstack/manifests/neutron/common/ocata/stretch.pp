class openstack::neutron::common::ocata::stretch(
) {
    require openstack::serverpackages::ocata::stretch

    package { 'neutron-common':
        ensure => 'present',
    }
}
