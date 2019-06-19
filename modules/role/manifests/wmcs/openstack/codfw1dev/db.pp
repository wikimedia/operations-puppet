class role::wmcs::openstack::codfw1dev::db {
    system::role { $name: }
    include ::profile::base::firewall
    include ::profile::openstack::codfw1dev::db
}
