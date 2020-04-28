class openstack::neutron::common::rocky::buster(
) {
    require openstack::serverpackages::rocky::buster

    package { 'neutron-common':
        ensure => 'present',
    }
}
