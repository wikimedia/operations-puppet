class openstack::neutron::common::victoria::buster(
) {
    require openstack::serverpackages::victoria::buster

    package { 'neutron-common':
        ensure => 'present',
    }
}
