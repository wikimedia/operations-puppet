class profile::openstack::labtestn::keystone::bootstrap(
    $region = hiera('profile::openstack::labtestn::region'),
    $db_pass = hiera('profile::openstack::labtestn::keystone::db_pass'),
    $admin_token = hiera('profile::openstack::labtestn::keystone::admin_token'),
    ) {

    require ::profile::openstack::labtestn::keystone::service
    class {'::profile::openstack::base::keystone::bootstrap':
        admin_token => $admin_token,
        db_pass     => $db_pass,
        region      => $region
    }
    contain '::profile::openstack::base::keystone::bootstrap'
}
