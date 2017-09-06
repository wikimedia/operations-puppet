class openstack2::common {

    $packages = [
        'ebtables',
        'mysql-common',
        'mysql-client-5.5',
        'python-netaddr',
    ]
    require_package($packages)
}
