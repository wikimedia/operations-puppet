class role::wmcs::openstack::labtestn::virt {
    system::role { $name: }
    include ::standard
    include ::profile::openstack::labtestn::cloudrepo
}
