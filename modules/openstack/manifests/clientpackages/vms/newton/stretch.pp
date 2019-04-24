# this is the class for use by VM instances in Cloud VPS. Don't use for HW servers
class openstack::clientpackages::vms::newton::stretch(
) {
    requires_realm('labs')
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
}
