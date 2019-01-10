class openstack::neutron::common::mitaka::stretch(
) {
    require openstack::serverpackages::mitaka::stretch

    package { 'neutron-common':
        ensure          => 'present',
        install_options => ['-t', 'jessie-backports'],
        require         => Package['sqlite3'],
    }
}
