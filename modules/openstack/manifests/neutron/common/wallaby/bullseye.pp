class openstack::neutron::common::wallaby::bullseye(
) {
    require openstack::serverpackages::wallaby::bullseye

    package { 'neutron-common':
        ensure => 'present',
    }
}
