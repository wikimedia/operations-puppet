class profile::openstack::codfw1dev::glance(
    String $version = lookup('profile::openstack::codfw1dev::version'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    String $db_pass = lookup('profile::openstack::codfw1dev::glance::db_pass'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::codfw1dev::glance::db_host'),
    String $ldap_user_pass = lookup('profile::openstack::codfw1dev::ldap_user_pass'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::codfw1dev::glance::api_bind_port'),
    String $ceph_pool = lookup('profile::openstack::codfw1dev::glance::ceph_pool'),
    Array[String] $glance_backends = lookup('profile::openstack::codfw1dev::glance_backends'),
    ) {

    class {'::profile::openstack::base::glance':
        version               => $version,
        openstack_controllers => $openstack_controllers,
        keystone_fqdn         => $keystone_fqdn,
        db_pass               => $db_pass,
        db_host               => $db_host,
        ldap_user_pass        => $ldap_user_pass,
        api_bind_port         => $api_bind_port,
        glance_backends       => $glance_backends,
        ceph_pool             => $ceph_pool,
        active                => true,
    }
    contain '::profile::openstack::base::glance'
}
