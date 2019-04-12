class role::wmcs::openstack::eqiad1::puppetmaster::backend {
    system::role { $name: }
    include ::standard
    include ::profile::openstack::eqiad1::clientpackages
    include ::profile::openstack::eqiad1::observerenv
    include ::profile::openstack::eqiad1::puppetmaster::backend
    include ::profile::openstack::base::optional_firewall
}
