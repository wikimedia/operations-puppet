class openstack::nova::common::rocky::stretch(
) {
    require ::openstack::serverpackages::rocky::stretch

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
