# SPDX-License-Identifier: Apache-2.0
# This is a transitional class for bootstrapping keystone
# with the LDAP provider.
class profile::openstack::base::keystone::bootstrap(
    $region = lookup('profile::openstack::base::region'),
    $db_user = lookup('profile::openstack::base::keystone::db_user'),
    $db_pass = lookup('profile::openstack::base::keystone::db_pass'),
    $admin_token = lookup('profile::openstack::base::keystone::admin_token'),
){

    class {'::openstack::keystone::bootstrap':
        region      => $region,
        db_user     => $db_user,
        db_pass     => $db_pass,
        admin_token => $admin_token,
    }
    contain '::openstack::keystone::bootstrap'
}
