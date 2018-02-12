# This is a transitional class for bootstrapping keystone
# with the LDAP provider.
class profile::openstack::base::keystone::bootstrap(
    $region = hiera('profile::openstack::base::region'),
    $db_user = hiera('profile::openstack::base::keystone::db_user'),
    $db_pass = hiera('profile::openstack::base::keystone::db_pass'),
    $admin_token = hiera('profile::openstack::base::keystone::admin_token'),
    ) {

    class {'::openstack::keystone::bootstrap':
        region      => $region
        db_user     => $db_user,
        db_pass     => $db_pass,
        admin_token => $admin_token,
    }
    contain '::openstack::keystone::bootstrap'
}
