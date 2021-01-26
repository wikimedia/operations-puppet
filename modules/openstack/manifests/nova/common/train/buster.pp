class openstack::nova::common::train::buster(
) {
    require ::openstack::serverpackages::train::buster

    $packages = [
        'unzip',
        'bridge-utils',
        'python-mysqldb',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }
}
