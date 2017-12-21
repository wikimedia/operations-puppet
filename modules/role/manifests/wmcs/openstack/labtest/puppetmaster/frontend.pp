class role::wmcs::openstack::labtest::puppetmaster::frontend {
    system::role { $name: }
    include ::standard
    include ::profile::base::firewall
    include ::profile::openstack::labtest::clientlib
    include ::profile::openstack::labtest::observerenv
    include ::profile::openstack::labtest::puppetmaster::frontend
}
