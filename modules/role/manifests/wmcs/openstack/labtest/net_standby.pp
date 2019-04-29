class role::wmcs::openstack::labtest::net_standby {
    system::role { $name: }
    include ::profile::standard
    include ::profile::openstack::labtest::clientpackages
    include ::profile::openstack::labtest::observerenv
}
