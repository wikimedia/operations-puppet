# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::keystone::service(
    $daemon_active = lookup('profile::openstack::base::keystone::daemon_active'),
    $version = lookup('profile::openstack::base::version'),
    $region = lookup('profile::openstack::base::region'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::base::openstack_control_nodes'),
    $osm_host = lookup('profile::openstack::base::osm_host'),
    $db_name = lookup('profile::openstack::base::keystone::db_name'),
    $db_user = lookup('profile::openstack::base::keystone::db_user'),
    $db_pass = lookup('profile::openstack::base::keystone::db_pass'),
    $db_host = lookup('profile::openstack::base::keystone::db_host'),
    $admin_workers = lookup('profile::openstack::base::keystone::admin_workers'),
    $public_workers = lookup('profile::openstack::base::keystone::public_workers'),
    $nova_db_pass = lookup('profile::openstack::base::nova::db_pass'),
    $token_driver = lookup('profile::openstack::base::keystone::token_driver'),
    $ldap_hosts = lookup('profile::openstack::base::ldap_hosts'),
    $ldap_config = lookup('ldap'),
    $ldap_base_dn = lookup('profile::openstack::base::ldap_base_dn'),
    $ldap_user_id_attribute = lookup('profile::openstack::base::ldap_user_id_attribute'),
    $ldap_user_name_attribute = lookup('profile::openstack::base::ldap_user_name_attribute'),
    $ldap_user_dn = lookup('profile::openstack::base::ldap_user_dn'),
    $ldap_user_pass = lookup('profile::openstack::base::ldap_user_pass'),
    $auth_protocol = lookup('profile::openstack::base::keystone::auth_protocol'),
    Stdlib::Fqdn $keystone_fqdn           = lookup('profile::openstack::base::keystone_api_fqdn'),
    $auth_port = lookup('profile::openstack::base::keystone::auth_port'),
    $public_port = lookup('profile::openstack::base::keystone::public_port'),
    $wiki_status_page_prefix = lookup('profile::openstack::base::keystone::wiki_status_page_prefix'),
    $wiki_status_consumer_token = lookup('profile::openstack::base::keystone::wiki_status_consumer_token'),
    $wiki_status_consumer_secret = lookup('profile::openstack::base::keystone::wiki_status_consumer_secret'),
    $wiki_status_access_token = lookup('profile::openstack::base::keystone::wiki_status_access_token'),
    $wiki_status_access_secret = lookup('profile::openstack::base::keystone::wiki_status_access_secret'),
    $wiki_consumer_token = lookup('profile::openstack::base::keystone::wiki_consumer_token'),
    $wiki_consumer_secret = lookup('profile::openstack::base::keystone::wiki_consumer_secret'),
    $wiki_access_token = lookup('profile::openstack::base::keystone::wiki_access_token'),
    $wiki_access_secret = lookup('profile::openstack::base::keystone::wiki_access_secret'),
    String $wsgi_server = lookup('profile::openstack::base::keystone::wsgi_server'),
    Array[Stdlib::IP::Address::V4::CIDR] $instance_ip_ranges = lookup('profile::openstack::base::keystone::instance_ip_ranges', {default_value => '[0.0.0.0/0]'}),
    String $wmcloud_domain_owner = lookup('profile::openstack::base::keystone::wmcloud_domain_owner'),
    String $bastion_project_id = lookup('profile::openstack::base::keystone::bastion_project_id'),
    Boolean $enforce_policy_scope = lookup('profile::openstack::base::keystone::enforce_policy_scope'),
    Boolean $enforce_new_policy_defaults = lookup('profile::openstack::base::keystone::enforce_new_policy_defaults'),
    Stdlib::Port $admin_bind_port = lookup('profile::openstack::base::admin_bind_port'),
    Stdlib::Port $public_bind_port = lookup('profile::openstack::base::public_bind_port'),
    Array[Stdlib::IP::Address::V4::Nosubnet] $prometheus_metricsinfra_reserved_ips = lookup('profile::openstack::base::prometheus_metricsinfra_reserved_ips'),
    Array[Stdlib::Port] $prometheus_metricsinfra_default_ports = lookup('profile::openstack::base::prometheus_metricsinfra_default_ports'),
    Array[Stdlib::Host] $haproxy_nodes = lookup('profile::openstack::base::haproxy_nodes'),
    Optional[Stdlib::IP::Address::V4] $cloud_private_supernet = lookup('profile::wmcs::cloud_private_subnet::supernet', {default_value => undef}),
    Stdlib::Fqdn $horizon_hostname = lookup('profile::openstack::base::horizon::webserver_hostname'),
) {

    $keystone_admin_uri = "${auth_protocol}://${keystone_fqdn}:${auth_port}/v3"

    include ::network::constants
    $ldap_rw_host = $ldap_config['rw-server']

    # Fernet key count.  We rotate once per day on each host.  That means that
    #  for our keys to live a week, we need at least 7*(number of hosts) keys
    #  at any one time.  Using 9 here instead because it costs us nothing
    #  and provides ample slack.
    $max_active_keys = $openstack_control_nodes.length * 9

    class {'::openstack::keystone::service':
        active                                => $daemon_active,
        version                               => $version,
        memcached_nodes                       => $openstack_control_nodes.map |$node| { $node['cloud_private_fqdn'] },
        max_active_keys                       => $max_active_keys,
        osm_host                              => $osm_host,
        db_name                               => $db_name,
        db_user                               => $db_user,
        db_pass                               => $db_pass,
        db_host                               => $db_host,
        admin_workers                         => $admin_workers,
        public_workers                        => $public_workers,
        token_driver                          => $token_driver,
        ldap_hosts                            => $ldap_hosts,
        ldap_rw_host                          => $ldap_rw_host,
        ldap_base_dn                          => $ldap_base_dn,
        ldap_user_id_attribute                => $ldap_user_id_attribute,
        ldap_user_name_attribute              => $ldap_user_name_attribute,
        ldap_user_dn                          => $ldap_user_dn,
        ldap_user_pass                        => $ldap_user_pass,
        region                                => $region,
        wiki_status_page_prefix               => $wiki_status_page_prefix,
        wiki_status_consumer_token            => $wiki_status_consumer_token,
        wiki_status_consumer_secret           => $wiki_status_consumer_secret,
        wiki_status_access_token              => $wiki_status_access_token,
        wiki_status_access_secret             => $wiki_status_access_secret,
        wiki_consumer_token                   => $wiki_consumer_token,
        wiki_consumer_secret                  => $wiki_consumer_secret,
        wiki_access_token                     => $wiki_access_token,
        wiki_access_secret                    => $wiki_access_secret,
        wsgi_server                           => $wsgi_server,
        instance_ip_ranges                    => $instance_ip_ranges,
        wmcloud_domain_owner                  => $wmcloud_domain_owner,
        bastion_project_id                    => $bastion_project_id,
        prod_networks                         => $::network::constants::production_networks + [$cloud_private_supernet],
        labs_networks                         => $::network::constants::cloud_networks,
        enforce_policy_scope                  => $enforce_policy_scope,
        enforce_new_policy_defaults           => $enforce_new_policy_defaults,
        keystone_admin_uri                    => $keystone_admin_uri,
        public_bind_port                      => $public_bind_port,
        admin_bind_port                       => $admin_bind_port,
        prometheus_metricsinfra_reserved_ips  => $prometheus_metricsinfra_reserved_ips,
        prometheus_metricsinfra_default_ports => $prometheus_metricsinfra_default_ports,
        horizon_hostname                      => $horizon_hostname,
    }
    contain '::openstack::keystone::service'

    class {'::openstack::util::admin_scripts':
        version => $version,
    }
    contain '::openstack::util::admin_scripts'

    ferm::service { 'keystone-api-backend':
        proto  => 'tcp',
        port   => "(${public_bind_port} ${admin_bind_port})",
        srange => "@resolve((${haproxy_nodes.join(' ')}))",
    }

    openstack::db::project_grants { 'keystone':
        access_hosts => $haproxy_nodes,
        db_name      => 'keystone',
        db_user      => $db_user,
        db_pass      => $db_pass,
        require      => Package['keystone'],
    }
}
