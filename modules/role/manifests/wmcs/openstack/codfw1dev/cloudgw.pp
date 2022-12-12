class role::wmcs::openstack::codfw1dev::cloudgw {
    system::role { $name: }
    # do not add base firewall
    include profile::base::production
    include profile::nftables::basefirewall
    include profile::base::cloud_production
    include profile::openstack::codfw1dev::cloudgw
}
