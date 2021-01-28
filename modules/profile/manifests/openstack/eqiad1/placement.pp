class profile::openstack::eqiad1::placement(
    String $version = lookup('profile::openstack::eqiad1::version'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::eqiad1::openstack_controllers'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    String $db_pass = lookup('profile::openstack::eqiad1::placement::db_pass'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::eqiad1::placement::db_host'),
    String $ldap_user_pass = lookup('profile::openstack::eqiad1::ldap_user_pass'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::eqiad1::placement::api_bind_port'),
    ) {

    class {'::profile::openstack::base::placement':
        version               => $version,
        openstack_controllers => $openstack_controllers,
        keystone_fqdn         => $keystone_fqdn,
        db_pass               => $db_pass,
        db_host               => $db_host,
        ldap_user_pass        => $ldap_user_pass,
        api_bind_port         => $api_bind_port,
    }
    contain '::profile::openstack::base::placement'
}
