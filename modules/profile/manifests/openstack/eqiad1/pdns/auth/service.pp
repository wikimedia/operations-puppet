class profile::openstack::eqiad1::pdns::auth::service(
    $host = hiera('profile::openstack::eqiad1::pdns::host'),
    $host_secondary = hiera('profile::openstack::eqiad1::pdns::host_secondary'),
    $db_pass = hiera('profile::openstack::eqiad1::pdns::db_pass'),
    $monitor_target_fqdn = hiera('profile::openstack::eqiad1::pdns::monitor_target_fqdn'),
    String $pdns_api_key = lookup('profile::openstack::eqiad1::pdns::api_key'),
    ) {

    $host_ip = ipresolve($host,4)
    $host_secondary_ip = ipresolve($host_secondary,4)

    # We're patching in our ipv4 address for db_host here;
    #  for unclear reasons 'localhost' doesn't work properly
    #  with the version of Mariadb installed on Jessie.
    class {'::profile::openstack::base::pdns::auth::service':
        host                => $host,
        host_secondary      => $host_secondary,
        db_pass             => $db_pass,
        db_host             => ipresolve($::fqdn,4),
        pdns_webserver      => true,
        pdns_api_key        => pdns_api_key,
        pdns_api_allow_from => ['127.0.0.1', ipresolve($host,4), ipresolve($host,6),
                                ipresolve($host_secondary,4), ipresolve($host_secondary,6)]
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
