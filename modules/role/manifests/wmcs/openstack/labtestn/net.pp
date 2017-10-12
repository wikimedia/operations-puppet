class role::wmcs::openstack::labtestn::net {
    system::role { $name: }
    include ::profile::openstack::labtestn::cloudrepo
    include ::profile::openstack::labtestn::nova::common
}
