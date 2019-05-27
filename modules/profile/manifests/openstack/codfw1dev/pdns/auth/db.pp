class profile::openstack::codfw1dev::pdns::auth::db(
    $designate_host = hiera('profile::openstack::codfw1dev::designate_host'),
    $designate_host_standby = hiera('profile::openstack::codfw1dev::designate_host_standby'),
    $second_region_designate_host = hiera('profile::openstack::codfw1dev::second_region_designate_host'),
    $pdns_db_pass = hiera('profile::openstack::codfw1dev::pdns::db_pass'),
    $pdns_admin_db_pass = hiera('profile::openstack::codfw1dev::pdns::db_admin_pass'),
    ) {

    class {'::profile::openstack::base::pdns::auth::db':
        designate_host               => $designate_host,
        designate_host_standby       => $designate_host_standby,
        second_region_designate_host => $second_region_designate_host,
        pdns_db_pass                 => $pdns_db_pass,
        pdns_admin_db_pass           => $pdns_admin_db_pass,
    }
}
