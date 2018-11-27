class openstack::clientpackages::newton::stretch(
) {
    # no special repo is configured, yet?

    $python3packages = [
        'python3-keystoneauth1',
        'python3-keystoneclient',
        'python3-novaclient',
        'python3-glanceclient',
        'python3-openstackclient',
        'python3-designateclient',
        'python3-neutronclient',
    ]

    package{ $python3packages:
        ensure => 'present',
    }

    package{ 'mariadb-client-10.1':
        ensure => 'present',
    }
}
