class openstack::neutron::common::ussuri::buster(
) {
    require openstack::serverpackages::ussuri::buster

    package { 'neutron-common':
        ensure => 'present',
    }
}
