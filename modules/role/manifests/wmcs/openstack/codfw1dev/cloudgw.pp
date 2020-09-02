class role::wmcs::openstack::codfw1dev::cloudgw {
    system::role { $name: }
    # do not add base firewall
    include ::profile::standard
    include ::profile::openstack::codfw1dev::cloudgw
}
