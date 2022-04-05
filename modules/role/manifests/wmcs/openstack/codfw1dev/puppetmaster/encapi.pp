class role::wmcs::openstack::codfw1dev::puppetmaster::encapi {
    system::role { $name: }

    include ::profile::base::production
    include ::profile::openstack::base::optional_firewall

    include ::profile::openstack::codfw1dev::puppetmaster::encapi
}
