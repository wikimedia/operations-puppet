class profile::openstack::eqiad1::keystone::service(
    $version = lookup('profile::openstack::eqiad1::version'),
    $region = lookup('profile::openstack::eqiad1::region'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::eqiad1::openstack_controllers'),
    $osm_host = lookup('profile::openstack::eqiad1::osm_host'),
    $db_host = lookup('profile::openstack::eqiad1::keystone::db_host'),
    $token_driver = lookup('profile::openstack::eqiad1::keystone::token_driver'),
    $db_user = lookup('profile::openstack::eqiad1::keystone::db_user'),
    $db_pass = lookup('profile::openstack::eqiad1::keystone::db_pass'),
    $db_name = lookup('profile::openstack::base::keystone::db_name'),
    $nova_db_pass = lookup('profile::openstack::eqiad1::nova::db_pass'),
    $ldap_hosts = lookup('profile::openstack::eqiad1::ldap_hosts'),
    $ldap_user_pass = lookup('profile::openstack::eqiad1::ldap_user_pass'),
    $wiki_status_consumer_token = lookup('profile::openstack::eqiad1::keystone::wiki_status_consumer_token'),
    $wiki_status_consumer_secret = lookup('profile::openstack::eqiad1::keystone::wiki_status_consumer_secret'),
    $wiki_status_access_token = lookup('profile::openstack::eqiad1::keystone::wiki_status_access_token'),
    $wiki_status_access_secret = lookup('profile::openstack::eqiad1::keystone::wiki_status_access_secret'),
    $wiki_consumer_token = lookup('profile::openstack::eqiad1::keystone::wiki_consumer_token'),
    $wiki_consumer_secret = lookup('profile::openstack::eqiad1::keystone::wiki_consumer_secret'),
    $wiki_access_token = lookup('profile::openstack::eqiad1::keystone::wiki_access_token'),
    $wiki_access_secret = lookup('profile::openstack::eqiad1::keystone::wiki_access_secret'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::eqiad1::designate_hosts'),
    $labweb_hosts = lookup('profile::openstack::eqiad1::labweb_hosts'),
    $puppetmaster_hostname = lookup('profile::openstack::eqiad1::puppetmaster_hostname'),
    $auth_port = lookup('profile::openstack::base::keystone::auth_port'),
    $public_port = lookup('profile::openstack::base::keystone::public_port'),
    Stdlib::Fqdn $keystone_fqdn           = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    Boolean $daemon_active = lookup('profile::openstack::eqiad1::keystone::daemon_active'),
    String $wsgi_server = lookup('profile::openstack::eqiad1::keystone::wsgi_server'),
    Stdlib::IP::Address::V4::CIDR $instance_ip_range = lookup('profile::openstack::eqiad1::keystone::instance_ip_range', {default_value => '0.0.0.0/0'}),
    String $wmcloud_domain_owner = lookup('profile::openstack::eqiad1::keystone::wmcloud_domain_owner'),
    String $bastion_project_id = lookup('profile::openstack::eqiad1::keystone::bastion_project_id'),
    Boolean $enforce_policy_scope = lookup('profile::openstack::eqiad1::keystone::enforce_policy_scope'),
    Boolean $enforce_new_policy_defaults = lookup('profile::openstack::eqiad1::keystone::enforce_new_policy_defaults'),
    Stdlib::Port $admin_bind_port = lookup('profile::openstack::eqiad1::keystone::admin_bind_port'),
    Stdlib::Port $public_bind_port = lookup('profile::openstack::eqiad1::keystone::public_bind_port'),
    Boolean $enable_app_credentials = lookup('profile::openstack::eqiad1::keystone::enable_app_credentials'),
    ) {

    require ::profile::openstack::eqiad1::clientpackages
    class {'::profile::openstack::base::keystone::service':
        daemon_active               => $daemon_active,
        version                     => $version,
        region                      => $region,
        openstack_controllers       => $openstack_controllers,
        osm_host                    => $osm_host,
        db_host                     => $db_host,
        token_driver                => $token_driver,
        db_pass                     => $db_pass,
        nova_db_pass                => $nova_db_pass,
        ldap_hosts                  => $ldap_hosts,
        ldap_user_pass              => $ldap_user_pass,
        wiki_status_consumer_token  => $wiki_status_consumer_token,
        wiki_status_consumer_secret => $wiki_status_consumer_secret,
        wiki_status_access_token    => $wiki_status_access_token,
        wiki_status_access_secret   => $wiki_status_access_secret,
        wiki_consumer_token         => $wiki_consumer_token,
        wiki_consumer_secret        => $wiki_consumer_secret,
        wiki_access_token           => $wiki_access_token,
        wiki_access_secret          => $wiki_access_secret,
        designate_hosts             => $designate_hosts,
        labweb_hosts                => $labweb_hosts,
        wsgi_server                 => $wsgi_server,
        instance_ip_range           => $instance_ip_range,
        wmcloud_domain_owner        => $wmcloud_domain_owner,
        bastion_project_id          => $bastion_project_id,
        enforce_policy_scope        => $enforce_policy_scope,
        enforce_new_policy_defaults => $enforce_new_policy_defaults,
        keystone_fqdn               => $keystone_fqdn,
        public_bind_port            => $public_bind_port,
        admin_bind_port             => $admin_bind_port,
        enable_app_credentials      => $enable_app_credentials,
    }
    contain '::profile::openstack::base::keystone::service'

    class {'::profile::openstack::base::keystone::hooks':
        version => $version,
    }
    contain '::profile::openstack::base::keystone::hooks'

    class {'::openstack::keystone::monitor::services':
        active         => true,
        auth_port      => $auth_port,
        public_port    => $public_port,
        contact_groups => 'wmcs-team-email',
    }
    contain '::openstack::keystone::monitor::services'

    class {'::openstack::monitor::spreadcheck':
    }

    # allow foreign designate(and co) to call back to admin auth port
    # to validate issued tokens
    ferm::rule{'main_designate_25357':
        ensure => 'present',
        rule   => "saddr @resolve((${join($designate_hosts,' ')})) proto tcp dport (25357) ACCEPT;",
    }

}
