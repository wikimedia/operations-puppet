class profile::openstack::labtestn::pdns::auth::db(
    $designate_host = hiera('profile::openstack::labtestn::designate_host'),
    $pdns_db_pass = hiera('profile::openstack::labtestn::pdns::db_pass'),
    $pdns_admin_db_pass = hiera('profile::openstack::labtestn::pdns::db_admin_pass'),
    ) {

    class {'::profile::openstack::base::pdns::auth::db':
        designate_host     => $designate_host,
        pdns_db_pass       => $pdns_db_pass,
        pdns_admin_db_pass => $pdns_admin_db_pass,
    }
}
