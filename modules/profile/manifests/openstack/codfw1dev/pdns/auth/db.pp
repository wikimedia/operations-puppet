class profile::openstack::codfw1dev::pdns::auth::db(
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::codfw1dev::designate_hosts'),
    $pdns_db_pass = lookup('profile::openstack::codfw1dev::pdns::db_pass'),
    $pdns_admin_db_pass = lookup('profile::openstack::codfw1dev::pdns::db_admin_pass'),
    ) {

    class {'::profile::openstack::base::pdns::auth::db':
        designate_hosts    => $designate_hosts,
        pdns_db_pass       => $pdns_db_pass,
        pdns_admin_db_pass => $pdns_admin_db_pass,
    }
}
