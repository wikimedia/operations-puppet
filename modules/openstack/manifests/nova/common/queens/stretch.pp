class openstack::nova::common::queens::stretch(
) {
    require ::openstack::serverpackages::queens::stretch

    $packages = [
        'unzip',
        'bridge-utils',
        'python3-mysqldb',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }
}
