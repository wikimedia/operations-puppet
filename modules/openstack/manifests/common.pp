class openstack::common {

    if os_version('ubuntu == trusty') {
        $packages = [
            'ebtables',
            'mysql-common',
            'mysql-client-5.5',
            'python-netaddr',
        ]
    } else {
        $packages = [
            'ebtables',
            'mysql-common',
            'mysql-client',
            'python-netaddr',
        ]
    }
    require_package($packages)
}
