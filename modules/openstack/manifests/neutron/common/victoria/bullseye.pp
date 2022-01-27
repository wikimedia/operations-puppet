class openstack::neutron::common::victoria::bullseye(
) {
    require openstack::serverpackages::victoria::bullseye

    package { 'neutron-common':
        ensure => 'present',
    }
}
