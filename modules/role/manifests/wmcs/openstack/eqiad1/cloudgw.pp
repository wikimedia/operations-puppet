class role::wmcs::openstack::eqiad1::cloudgw {
    system::role { $name: }
    include profile::base::production
    # do not add ferm-based base firewall profile, these servers use native nftables
    include profile::nftables::basefirewall
    include profile::openstack::eqiad1::cloudgw
}
