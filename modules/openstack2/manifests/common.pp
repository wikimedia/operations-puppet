class openstack2::common {

    $packages = [
        'unzip',
        'vblade-persist',
        'bridge-utils',
        'ebtables',
        'mysql-common',
        'mysql-client-5.5',
        'python-mysqldb',
        'python-netaddr',
        'radvd',
    ]
    require_package($packages)
}
