class profile::openstack::codfw1dev::pdns::auth::service(
    $host = hiera('profile::openstack::codfw1dev::pdns::host'),
    $db_pass = hiera('profile::openstack::codfw1dev::pdns::db_pass'),
    ) {

    # We're patching in our ipv4 address for db_host here;
    #  for unclear reasons 'localhost' doesn't work properly
    #  with the version of Mariadb installed on Jessie.
    class {'::profile::openstack::base::pdns::auth::service':
        host    => $host,
        db_pass => $db_pass,
        db_host => ipresolve($host,4)
    }

    class {'::profile::openstack::base::pdns::auth::monitor::pdns_control':}
}
