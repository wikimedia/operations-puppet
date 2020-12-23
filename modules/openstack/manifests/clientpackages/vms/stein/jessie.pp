# this is the class for use by VM instances in Cloud VPS. Don't use for HW servers
class openstack::clientpackages::vms::stein::jessie(
) {
    requires_realm('labs')
    # This is a placeholder for the few remaining Jessie VMs.  It will
    #  let us install whatever are the default versions of Jessie client
    #  packages, probably 'mitaka'
}
