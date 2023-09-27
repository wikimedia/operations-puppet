class role::wmcs::openstack::eqiad1::cloudgw {
    system::role { $name: }
    include profile::base::production
    include profile::firewall
    include profile::base::cloud_production
    include profile::openstack::eqiad1::cloudgw
}
