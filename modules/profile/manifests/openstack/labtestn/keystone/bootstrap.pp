class profile::openstack::labtestn::keystone::bootstrap(
    $region = hiera('profile::openstack::labtestn::region'),
    $db_name = hiera('profile::openstack::labtestn::keystone::db_name'),
    $db_user = hiera('profile::openstack::labtestn::keystone::db_user'),
    $db_pass = hiera('profile::openstack::labtestn::keystone::db_pass'),
    $db_host = hiera('profile::openstack::labtestn::keystone::db_host'),
    $admin_token = hiera('profile::openstack::labtestn::keystone::admin_token'),
    ) {

    require ::profile::openstack::labtestn::keystone::service
    class {'::profile::openstack::base::keystone::bootstrap':
        admin_token => $admin_token,
        db_user     => $db_user,
        db_pass     => $db_pass,
        region      => $region
    }
    contain '::profile::openstack::base::keystone::bootstrap'
}
