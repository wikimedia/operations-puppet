class profile::openstack::codfw1dev::keystone::bootstrap(
    $region = hiera('profile::openstack::codfw1dev::region'),
    $db_pass = hiera('profile::openstack::codfw1dev::keystone::db_pass'),
    $admin_token = hiera('profile::openstack::codfw1dev::keystone::admin_token'),
    ) {

    require ::profile::openstack::codfw1dev::keystone::service
    class {'::profile::openstack::base::keystone::bootstrap':
        admin_token => $admin_token,
        db_pass     => $db_pass,
        region      => $region
    }
    contain '::profile::openstack::base::keystone::bootstrap'
}
