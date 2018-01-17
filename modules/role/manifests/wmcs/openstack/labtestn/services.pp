class role::wmcs::openstack::labtestn::services {
    system::role { $name: }
    include ::standard
    include ::profile::base::firewall
    include ::profile::openstack::labtestn::cloudrepo
}
