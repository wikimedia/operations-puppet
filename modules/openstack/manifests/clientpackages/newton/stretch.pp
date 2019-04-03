class openstack::clientpackages::newton::stretch(
) {
    # no special repo is configured, yet?
    # i.e, openstack::commonpackages::newton or something similar
    require openstack::clientpackages::anyopenstack_anydebian

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
}
