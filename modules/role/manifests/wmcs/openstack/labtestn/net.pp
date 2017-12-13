class role::wmcs::openstack::labtestn::net {
    system::role { $name: }
    # Do not add base firewall
    include ::standard
    include ::profile::openstack::labtestn::clientlib
}
