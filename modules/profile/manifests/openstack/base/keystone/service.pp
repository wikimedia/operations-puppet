class profile::openstack::base::keystone::service(
    $daemon_active = lookup('profile::openstack::base::keystone::daemon_active'),
    $version = lookup('profile::openstack::base::version'),
    $region = lookup('profile::openstack::base::region'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    $osm_host = lookup('profile::openstack::base::osm_host'),
    $db_name = lookup('profile::openstack::base::keystone::db_name'),
    $db_user = lookup('profile::openstack::base::keystone::db_user'),
    $db_pass = lookup('profile::openstack::base::keystone::db_pass'),
    $db_host = lookup('profile::openstack::base::keystone::db_host'),
    $db_max_pool_size = lookup('profile::openstack::base::keystone::db_max_pool_size'),
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
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::base::designate_hosts'),
    $labweb_hosts = lookup('profile::openstack::base::labweb_hosts'),
    String $wsgi_server = lookup('profile::openstack::base::keystone::wsgi_server'),
    Stdlib::IP::Address::V4::CIDR $instance_ip_range = lookup('profile::openstack::base::keystone::instance_ip_range', {default_value => '0.0.0.0/0'}),
    String $wmcloud_domain_owner = lookup('profile::openstack::base::keystone::wmcloud_domain_owner'),
    String $bastion_project_id = lookup('profile::openstack::base::keystone::bastion_project_id'),
    Boolean $enforce_policy_scope = lookup('profile::openstack::base::keystone::enforce_policy_scope'),
    Boolean $enforce_new_policy_defaults = lookup('profile::openstack::base::keystone::enforce_new_policy_defaults'),
    Stdlib::Port $admin_bind_port = lookup('profile::openstack::base::admin_bind_port'),
    Stdlib::Port $public_bind_port = lookup('profile::openstack::base::public_bind_port'),
    Array[String] $service_domains = lookup('profile::openstack::base::keystone::service_domains'),
    ) {

    $keystone_admin_uri = "${auth_protocol}://${keystone_fqdn}:${auth_port}/v3"

    include ::network::constants
    $prod_networks = join($::network::constants::production_networks, ' ')
    $labs_networks = join($::network::constants::labs_networks, ' ')
    $ldap_rw_host = $ldap_config['rw-server']

    class {'::openstack::keystone::service':
        active                      => $daemon_active,
        version                     => $version,
        controller_hosts            => $openstack_controllers,
        osm_host                    => $osm_host,
        db_name                     => $db_name,
        db_user                     => $db_user,
        db_pass                     => $db_pass,
        db_host                     => $db_host,
        db_max_pool_size            => $db_max_pool_size,
        admin_workers               => $admin_workers,
        public_workers              => $public_workers,
        token_driver                => $token_driver,
        ldap_hosts                  => $ldap_hosts,
        ldap_rw_host                => $ldap_rw_host,
        ldap_base_dn                => $ldap_base_dn,
        ldap_user_id_attribute      => $ldap_user_id_attribute,
        ldap_user_name_attribute    => $ldap_user_name_attribute,
        ldap_user_dn                => $ldap_user_dn,
        ldap_user_pass              => $ldap_user_pass,
        region                      => $region,
        wiki_status_page_prefix     => $wiki_status_page_prefix,
        wiki_status_consumer_token  => $wiki_status_consumer_token,
        wiki_status_consumer_secret => $wiki_status_consumer_secret,
        wiki_status_access_token    => $wiki_status_access_token,
        wiki_status_access_secret   => $wiki_status_access_secret,
        wiki_consumer_token         => $wiki_consumer_token,
        wiki_consumer_secret        => $wiki_consumer_secret,
        wiki_access_token           => $wiki_access_token,
        wiki_access_secret          => $wiki_access_secret,
        wsgi_server                 => $wsgi_server,
        instance_ip_range           => $instance_ip_range,
        wmcloud_domain_owner        => $wmcloud_domain_owner,
        bastion_project_id          => $bastion_project_id,
        prod_networks               => $::network::constants::production_networks,
        labs_networks               => $::network::constants::labs_networks,
        enforce_policy_scope        => $enforce_policy_scope,
        enforce_new_policy_defaults => $enforce_new_policy_defaults,
        keystone_admin_uri          => $keystone_admin_uri,
        public_bind_port            => $public_bind_port,
        admin_bind_port             => $admin_bind_port,
        service_domains             => $service_domains,
    }
    contain '::openstack::keystone::service'

    class {'::openstack::util::admin_scripts':
        version => $version,
    }
    contain '::openstack::util::admin_scripts'

    # keystone admin API only for openstack services that might need it.
    #
    # Note that because keystone admin uses a weird, extremely-high-number
    #  port by default, we need to use a non-standard port for its
    #  tls port as well: 25357 rather than the more expected 225357

    ferm::service { 'keystone_admin':
        proto  => 'tcp',
        port   => '(35357 25357)',
        srange => "(@resolve((${openstack_controllers.join(' ')} ${designate_hosts.join(' ')} ${labweb_hosts.join(' ')})))",
    }

    $nova_hosts_ranges = $::network::constants::cloud_nova_hosts_ranges[$region]

    ferm::service { 'keystone-admin-nova-hosts':
        proto  => 'tcp',
        port   => '(35357 25357)',
        srange => "(${nova_hosts_ranges.join(' ')})",
    }

    ferm::rule{'keystone_public':
        ensure => 'present',
        rule   => "saddr (${prod_networks} ${labs_networks}
                             ) proto tcp dport (5000 25000) ACCEPT;",
    }

    openstack::db::project_grants { 'keystone':
        access_hosts => $openstack_controllers,
        db_name      => 'keystone',
        db_user      => $db_user,
        db_pass      => $db_pass,
    }
}
