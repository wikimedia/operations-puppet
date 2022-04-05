class role::wmcs::openstack::eqiad1::puppetmaster::frontend_vm {
    system::role { $name: }
    include ::profile::base::production
    include ::profile::openstack::eqiad1::observerenv
    include ::profile::openstack::eqiad1::puppetmaster::frontend
    include ::profile::openstack::eqiad1::puppetmaster::encapi
    include ::profile::openstack::base::optional_firewall
}
