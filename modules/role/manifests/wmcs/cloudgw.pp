class role::wmcs::cloudgw {
    system::role { $name: }

    include profile::base::production
    include profile::firewall
    include profile::base::cloud_production
    include profile::wmcs::cloudgw
}
