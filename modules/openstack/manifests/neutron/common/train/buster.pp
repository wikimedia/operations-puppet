class openstack::neutron::common::train::buster(
) {
    require openstack::serverpackages::train::buster

    package { 'neutron-common':
        ensure => 'present',
    }
}
