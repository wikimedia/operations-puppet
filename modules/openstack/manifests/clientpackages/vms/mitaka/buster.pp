# this is the class for use by VM instances in Cloud VPS. Don't use for HW servers
#
# We no longer have openstack mitaka API servers. This class can eventually go
# away safely when no hiera 'profile::openstack::xx::version' is set to mitaka.
#
class openstack::clientpackages::vms::mitaka::buster(
) {
    requires_realm('labs')

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
