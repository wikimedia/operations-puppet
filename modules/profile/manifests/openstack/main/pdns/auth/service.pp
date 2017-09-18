class profile::openstack::main::pdns::auth::service(
    $host = hiera('profile::openstack::main::pdns::host'),
    $host_secondary = hiera('profile::openstack::main::pdns::host_secondary'),
    $db_pass = hiera('profile::openstack::main::pdns::db_pass'),
    $monitor_target_fqdn = hiera('profile::openstack::main::pdns::monitor_target_fqdn'),
    ) {

    $host_ip = ipresolve($host,4)
    $host_secondary_ip = ipresolve($host_secondary,4)

    class {'::profile::openstack::base::pdns::auth::service':
        host           => $host,
        host_secondary => $host_secondary,
        db_pass        => $db_pass,
    }

    class {'::profile::openstack::base::pdns::auth::monitor::pdns_control':}

    # This could be handled with two profiles and should be
    #  if it becomes more complex than this bit of logic.
    # Also contingent on the host address resolving to the same
    #  IP as the public SOA record.
    if ($host_ip == $::ipaddress) {
        $auth_dns_host = $host
    }
    elsif ($host_secondary_ip == $::ipaddress) {
        $auth_dns_host = $host_secondary
    }
    else {
        # Valid auth DNS servers all resolve to the main
        #  server IP for now.
        fail("${::ipaddress} is not valid for ${name}")
    }

    class {'::profile::openstack::base::pdns::auth::monitor::host_check':
        target_host => $auth_dns_host,
        target_fqdn => $monitor_target_fqdn,
    }
}
