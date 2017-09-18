class profile::openstack::main::pdns::auth::service(
    $host = hiera('profile::openstack::main::pdns::host'),
    $db_pass = hiera('profile::openstack::main::pdns::db_pass'),
    $target_fqdn = hiera('profile::openstack::main::pdns::monitor_target_fqdn'),
    ) {

    class {'::profile::openstack::base::pdns::auth::service':
        host    => $host,
        db_pass => $db_pass,
    }

    class {'profile::openstack::base::pdns::auth::monitor::host_check':
        auth_soa_name => $host,
        target_fqdn   => $target_fqdn,
    }

    class {'::profile::openstack::base::pdns::auth::monitor::pdns_control':}
}
