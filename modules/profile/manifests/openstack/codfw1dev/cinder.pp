class profile::openstack::codfw1dev::cinder(
    String $version = lookup('profile::openstack::codfw1dev::version'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    String $db_pass = lookup('profile::openstack::codfw1dev::cinder::db_pass'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::codfw1dev::cinder::db_host'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::codfw1dev::cinder::api_bind_port'),
    String $ceph_pool = lookup('profile::openstack::codfw1dev::cinder::ceph_pool'),
    String $rabbit_pass = lookup('profile::openstack::codfw1dev::nova::rabbit_pass'),
    String $ldap_user_pass = lookup('profile::openstack::codfw1dev::cinder::ldap_user_pass'),
    ) {

    class {'::profile::openstack::base::cinder':
        version               => $version,
        openstack_controllers => $openstack_controllers,
        keystone_fqdn         => $keystone_fqdn,
        db_pass               => $db_pass,
        db_host               => $db_host,
        api_bind_port         => $api_bind_port,
        ceph_pool             => $ceph_pool,
        ldap_user_pass        => $ldap_user_pass,
        rabbit_pass           => $rabbit_pass,
        active                => true,
    }
}
