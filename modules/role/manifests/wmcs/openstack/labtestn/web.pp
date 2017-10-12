class role::wmcs::openstack::labtestn::web {
    system::role { $name: }
    include ::profile::openstack::labtestn::cloudrepo
    include ::profile::openstack::labtestn::clientlib
    include ::profile::openstack::labtestn::observerenv
}
