class profile::openstack::labtestn::pdns::auth::service(
    $host = hiera('profile::openstack::labtestn::pdns::host'),
    $host_secondary = hiera('profile::openstack::labtestn::pdns::host_secondary'),
    $target_fqdn = hiera('profile::openstack::labtestn::pdns::target_fqdn'),
    $db_pass = hiera('profile::openstack::labtestn::pdns::db_pass'),
    ) {

    class {'::profile::openstack::base::pdns::auth::service':
        host           => $host,
        host_secondary => $host_secondary,
        target_fqdn    => $target_fqdn,
        db_pass        => $db_pass,
    }

    class {'::profile::openstack::base::pdns::auth::monitor::pdns_control':}
}
