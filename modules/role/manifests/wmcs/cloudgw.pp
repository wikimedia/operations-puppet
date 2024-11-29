class role::wmcs::cloudgw {
    include profile::base::production
    include profile::firewall
    include profile::base::cloud_production
    include profile::wmcs::cloudgw
    include profile::wmcs::cloudgw::blackboxmonitor
}
