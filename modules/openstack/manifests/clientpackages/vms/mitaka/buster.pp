# this is the class for use by VM instances in Cloud VPS. Don't use for HW servers
class openstack::clientpackages::vms::mitaka::buster(
) {
    requires_realm('labs')
    notify { "${title}: no special configuration yet": }
}
