class role::wmcs::openstack::labtest::net_standby {
    system::role { $name: }
    include ::standard
    include ::profile::openstack::labtest::cloudrepo
    include ::profile::openstack::labtest::clientlib
    include ::profile::openstack::labtest::observerenv
}
