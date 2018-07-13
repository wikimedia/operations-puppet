class role::wmcs::openstack::labtestn::services {
    system::role { $name: }
    include ::standard
    include ::profile::base::firewall

    # We need a separate designate to listen to events in labtestn.
    # For now, though, just use the same DNS setup as labtest.  Eventually
    #  we'll have to figure out how to migrate over to a new dns server here.

    # This designate uses the same designate DB as the labtest designate;
    # we want DNS to know about the state of both regions in a single place.
    include ::profile::openstack::labtestn::designate::service
}
