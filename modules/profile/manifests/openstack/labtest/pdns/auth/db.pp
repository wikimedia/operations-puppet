class profile::openstack::labtest::pdns::auth::db(
    $designate_host = hiera('profile::openstack::labtest::designate_host'),
    $pdns_db_pass = hiera('profile::openstack::labtest::pdns::db_pass'),
    $pdns_admin_db_pass = hiera('profile::openstack::labtest::pdns::db_admin_pass'),
    ) {

    class {'::profile::openstack::base::pdns::auth::db':
        designate_host     => $designate_host,
        pdns_db_pass       => $pdns_db_pass,
        pdns_admin_db_pass => $pdns_admin_db_pass,
    }
}
