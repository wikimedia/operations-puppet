class profile::openstack::codfw1dev::barbican(
    String $version = lookup('profile::openstack::codfw1dev::version'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    String $db_user = lookup('profile::openstack::codfw1dev::barbican::db_user'),
    String $db_pass = lookup('profile::openstack::codfw1dev::barbican::db_pass'),
    String $db_name = lookup('profile::openstack::codfw1dev::barbican::db_name'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::codfw1dev::barbican::db_host'),
    String $ldap_user_pass = lookup('profile::openstack::codfw1dev::ldap_user_pass'),
    Stdlib::Port $bind_port = lookup('profile::openstack::codfw1dev::barbican::bind_port'),
    String $crypto_kek = lookup('profile::openstack::codfw1dev::barbican::kek'),
    ) {

    class {'::profile::openstack::base::barbican':
        version               => $version,
        openstack_controllers => $openstack_controllers,
        keystone_fqdn         => $keystone_fqdn,
        db_user               => $db_user,
        db_pass               => $db_pass,
        db_name               => $db_name,
        db_host               => $db_host,
        ldap_user_pass        => $ldap_user_pass,
        bind_port             => $bind_port,
        crypto_kek            => $crypto_kek,
    }
    contain '::profile::openstack::base::barbican'
}
