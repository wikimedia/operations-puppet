class role::wmcs::openstack::eqiad1::puppetmaster::backend_vm {
    system::role { $name: }
    include ::profile::standard
    include ::profile::openstack::eqiad1::observerenv
    include ::profile::openstack::eqiad1::puppetmaster::backend
    include ::profile::openstack::base::optional_firewall
}
