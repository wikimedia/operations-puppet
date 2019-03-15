class openstack::clientpackages::mitaka::trusty(
) {
    # repo is same as for server packages!
    include ::openstack::serverpackages::mitaka::trusty

    # TODO: What is this doing here?
    $mainpackages = [
        'mysql-client-5.5',
        'mysql-common',
    ]

    package { $mainpackages:
        ensure => 'present',
    }
}
