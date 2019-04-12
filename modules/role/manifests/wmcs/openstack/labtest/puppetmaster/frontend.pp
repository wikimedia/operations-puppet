class role::wmcs::openstack::labtest::puppetmaster::frontend {
    system::role { $name: }
    include ::standard
    include ::profile::openstack::labtest::clientpackages
    include ::profile::openstack::labtest::observerenv
    include ::profile::openstack::labtest::puppetmaster::frontend
    include ::profile::openstack::base::optional_firewall
}
