class role::wmcs::openstack::eqiad1::puppetmaster::frontend_vm {
    system::role { $name: }
    include ::profile::standard
    include ::profile::openstack::eqiad1::observerenv
    include ::profile::openstack::eqiad1::puppetmaster::frontend
    include ::profile::openstack::base::optional_firewall
}
