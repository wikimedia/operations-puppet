class role::wmcs::openstack::labtest::web {
    system::role { $name: }
    include ::profile::openstack::labtest::cloudrepo
    include ::profile::openstack::labtest::clientlib
    include ::profile::openstack::labtest::observerenv
}
