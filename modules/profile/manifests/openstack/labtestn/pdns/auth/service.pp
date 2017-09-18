class profile::openstack::labtestn::pdns::auth::service(
    $host = hiera('profile::openstack::labtestn::pdns::host'),
    $db_pass = hiera('profile::openstack::labtestn::pdns::db_pass'),
    ) {

    class {'::profile::openstack::base::pdns::auth::service':
        host    => $host,
        db_pass => $db_pass,
    }

    class {'::profile::openstack::base::pdns::auth::monitor::pdns_control':}
}
