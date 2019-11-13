# this is the class for use by VM instances in Cloud VPS. Don't use for HW servers
#
# We no longer have openstack mitaka API servers. This class can eventually go
# away safely when no hiera 'profile::openstack::xx::version' is set to mitaka.
#
class openstack::clientpackages::vms::mitaka::stretch(
) {
    requires_realm('labs')
}
