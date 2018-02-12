# This is a transitional class for bootstrapping keystone
# with the LDAP provider.
class profile::openstack::base::keystone::bootstrap(
    $region = hiera('profile::openstack::base::region'),
    $db_name = hiera('profile::openstack::base::keystone::db_name'),
    $db_user = hiera('profile::openstack::base::keystone::db_user'),
    $db_pass = hiera('profile::openstack::base::keystone::db_pass'),
    $db_host = hiera('profile::openstack::base::keystone::db_host'),
    $admin_token = hiera('profile::openstack::base::keystone::admin_token'),
    ) {

    class {'::openstack::keystone::bootstrap':
        admin_token => $admin_token,
        db_user     => $db_user,
        db_pass     => $db_pass,
        region      => $region
    }
    contain '::openstack::keystone::bootstrap'
}
