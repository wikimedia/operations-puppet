class profile::openstack::codfw1dev::cinder(
    String $version = lookup('profile::openstack::codfw1dev::version'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    String $db_pass = lookup('profile::openstack::codfw1dev::cinder::db_pass'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::codfw1dev::cinder::db_host'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::codfw1dev::cinder::api_bind_port'),
    String $ceph_pool = lookup('profile::openstack::codfw1dev::cinder::ceph_pool'),
    String $rabbit_pass = lookup('profile::openstack::codfw1dev::nova::rabbit_pass'),
    String $ldap_user_pass = lookup('profile::openstack::codfw1dev::ldap_user_pass'),
    String $region = lookup('profile::openstack::codfw1dev::region'),
    String $ceph_client_keydata = lookup('profile::ceph::client::rbd::cinder_client_keydata'),
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
        region                => $region,
        active                => true,
    }

    # The keydata used in this step is pre-created on one of the ceph mon hosts
    # typically with the 'ceph auth get-or-create' command
    file { '/etc/ceph/ceph.client.codfw1dev-cinder.keyring':
        ensure    => present,
        mode      => '0440',
        owner     => cinder,
        group     => cinder,
        content   => "[client.codfw1dev-cinder]\n        key = ${ceph_client_keydata}\n",
        show_diff => false,
        require   => Package['ceph-common'],
    }
}
