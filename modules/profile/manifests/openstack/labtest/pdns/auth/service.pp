class profile::openstack::labtest::pdns::auth::service(
    $host = hiera('profile::openstack::labtest::pdns::host'),
    $db_pass = hiera('profile::openstack::labtest::pdns::db_pass'),
    ) {

    class {'::profile::openstack::base::pdns::auth::service':
        host    => $host,
        db_pass => $db_pass,
    }

    class {'::profile::openstack::base::pdns::auth::monitor::pdns_control':}
}
