class role::wmcs::openstack::labtest::puppetmaster::frontend {
    system::role { $name: }
    include ::profile::openstack::labtest::clientlib
    include ::profile::openstack::labtest::observerenv
    include ::profile::openstack::labtest::puppetmaster::frontend
}
