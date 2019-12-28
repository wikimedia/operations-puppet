class openstack::nova::common::pike::stretch(
) {
    require ::openstack::serverpackages::pike::stretch

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
