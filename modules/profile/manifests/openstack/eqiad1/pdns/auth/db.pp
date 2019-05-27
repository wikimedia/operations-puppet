class profile::openstack::eqiad1::pdns::auth::db(
    $designate_host = hiera('profile::openstack::eqiad1::designate_host'),
    $designate_host_standby = hiera('profile::openstack::eqiad1::designate_host_standby'),
    $second_region_designate_host = hiera('profile::openstack::eqiad1::second_region_designate_host'),
    $pdns_db_pass = hiera('profile::openstack::eqiad1::pdns::db_pass'),
    $pdns_admin_db_pass = hiera('profile::openstack::eqiad1::pdns::db_admin_pass'),
    ) {

    class {'::profile::openstack::base::pdns::auth::db':
        designate_host               => $designate_host,
        designate_host_standby       => $designate_host_standby,
        second_region_designate_host => $second_region_designate_host,
        pdns_db_pass                 => $pdns_db_pass,
        pdns_admin_db_pass           => $pdns_admin_db_pass,
    }
}
