class openstack::nova::common::victoria::buster(
) {
    require ::openstack::serverpackages::victoria::buster

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
