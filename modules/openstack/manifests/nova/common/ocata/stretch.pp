class openstack::nova::common::ocata::stretch(
) {
    require ::openstack::serverpackages::ocata::stretch

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
