class role::wmcs::openstack::codfw1dev::manila_sharecontroller {
    system::role{ $name: }

    # this is meant to be deployed on a virtual machine inside CloudVPS
    requires_realm('labs')

    # so far we only have the manila-share package available for bullseye,
    # adding it for buster should be trivial, but ... worth it?
    debian::codename::require::min('bullseye')

    include profile::openstack::coddfw1dev::manila::sharecontroller
}
