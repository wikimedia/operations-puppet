class role::wmcs::openstack::codfw1dev::db {
    include profile::base::production
    include profile::firewall
    include profile::base::cloud_production

    include profile::openstack::codfw1dev::db
}
