class role::wmcs::openstack::codfw1dev::puppetmaster::encapi {
    include profile::base::production
    include profile::openstack::base::optional_firewall
    include profile::base::cloud_production

    include profile::openstack::codfw1dev::puppetmaster::encapi
}
