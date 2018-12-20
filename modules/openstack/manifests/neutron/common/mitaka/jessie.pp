class openstack::neutron::common::mitaka::jessie(
) {
    require openstack::serverpackages::mitaka::jessie

    package { 'neutron-common':
        ensure          => 'present',
        install_options => ['-t', 'jessie-backports'],
    }
}
