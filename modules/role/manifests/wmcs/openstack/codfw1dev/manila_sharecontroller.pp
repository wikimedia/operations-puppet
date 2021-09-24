class role::wmcs::openstack::codfw1dev::manila_sharecontroller {
    system::role{ $name: }

    # this is meant to be deployed on a virtual machine inside CloudVPS
    requires_realm('labs')

    include profile::openstack::coddfw1dev::manila::sharecontroller
}
