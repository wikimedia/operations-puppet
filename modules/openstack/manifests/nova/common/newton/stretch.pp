class openstack::nova::common::newton::stretch(
) {
    require ::openstack::serverpackages::newton::stretch

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
