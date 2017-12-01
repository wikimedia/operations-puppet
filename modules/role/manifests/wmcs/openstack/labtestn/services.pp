class role::wmcs::openstack::labtestn::services {
    system::role { $name: }
    include ::standard
    include ::profile::openstack::labtestn::cloudrepo
}
