class openstack::neutron::common::stein::buster(
) {
    require openstack::serverpackages::stein::buster

    package { 'neutron-common':
        ensure => 'present',
    }
}
