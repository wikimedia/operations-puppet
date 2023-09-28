class profile::openstack::base::placement(
    String $version = lookup('profile::openstack::base::version'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    String $db_user = lookup('profile::openstack::base::placement::db_user'),
    String $db_name = lookup('profile::openstack::base::placement::db_name'),
    String $db_pass = lookup('profile::openstack::base::placement::db_pass'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::base::placement::db_host'),
    String $ldap_user_pass = lookup('profile::openstack::base::ldap_user_pass'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::base::placement::api_bind_port'),
    Array[Stdlib::Fqdn] $haproxy_nodes = lookup('profile::openstack::base::haproxy_nodes'),
) {
    class { '::openstack::placement::service':
        memcached_nodes => $openstack_controllers,
        version         => $version,
        keystone_fqdn   => $keystone_fqdn,
        db_user         => $db_user,
        db_pass         => $db_pass,
        db_name         => $db_name,
        db_host         => $db_host,
        ldap_user_pass  => $ldap_user_pass,
        api_bind_port   => $api_bind_port,
    }

    include ::network::constants
    $prod_networks = join($network::constants::production_networks, ' ')
    $labs_networks = join($network::constants::labs_networks, ' ')

    ferm::service { 'placement-api-backend':
        proto  => 'tcp',
        port   => $api_bind_port,
        srange => "@resolve((${haproxy_nodes.join(' ')}))",
    }

    # TODO: move to haproxy/cloudlb profiles
    ferm::service { 'placement-api-access':
        proto  => 'tcp',
        port   => 28778,
        srange => "(${prod_networks} ${labs_networks})",
    }

    openstack::db::project_grants { 'placement':
        access_hosts => $haproxy_nodes,
        db_name      => 'placement',
        db_user      => $db_user,
        db_pass      => $db_pass,
    }
}
