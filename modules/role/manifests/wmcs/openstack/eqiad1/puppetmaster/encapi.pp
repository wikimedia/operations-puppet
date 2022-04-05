class role::wmcs::openstack::eqiad1::puppetmaster::encapi {
    system::role { $name: }

    include ::profile::base::production
    include ::profile::openstack::base::optional_firewall

    include ::profile::openstack::eqiad1::puppetmaster::encapi
}
