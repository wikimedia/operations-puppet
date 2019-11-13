# this is the class for use by VM instances in Cloud VPS. Don't use for HW servers
class openstack::clientpackages::vms::ocata::buster(
) {
    requires_realm('labs')
    # It seems we don't need any special magic for this Debian/Openstack combo.
    # That's OK. All config this combo gets was probably applied via:
    #
    # role::wmcs::instance
    #  profile::openstack::eqiad1::clientpackages::vms
    #   profile::openstack::base::clientpackages::vms
    #    openstack::clientpackages::vms::common
}
