class profile::openstack::eqiad1::keystone::service(
    $version = hiera('profile::openstack::eqiad1::version'),
    $region = hiera('profile::openstack::eqiad1::region'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::eqiad1::openstack_controllers'),
    $keystone_host = hiera('profile::openstack::eqiad1::keystone_host'),
    $osm_host = hiera('profile::openstack::eqiad1::osm_host'),
    $db_host = hiera('profile::openstack::eqiad1::keystone::db_host'),
    $token_driver = hiera('profile::openstack::eqiad1::keystone::token_driver'),
    $db_user = hiera('profile::openstack::eqiad1::keystone::db_user'),
    $db_pass = hiera('profile::openstack::eqiad1::keystone::db_pass'),
    $db_name = hiera('profile::openstack::base::keystone::db_name'),
    $nova_db_pass = hiera('profile::openstack::eqiad1::nova::db_pass'),
    $ldap_hosts = hiera('profile::openstack::eqiad1::ldap_hosts'),
    $ldap_user_pass = hiera('profile::openstack::eqiad1::ldap_user_pass'),
    $wiki_status_consumer_token = hiera('profile::openstack::eqiad1::keystone::wiki_status_consumer_token'),
    $wiki_status_consumer_secret = hiera('profile::openstack::eqiad1::keystone::wiki_status_consumer_secret'),
    $wiki_status_access_token = hiera('profile::openstack::eqiad1::keystone::wiki_status_access_token'),
    $wiki_status_access_secret = hiera('profile::openstack::eqiad1::keystone::wiki_status_access_secret'),
    $wiki_consumer_token = hiera('profile::openstack::eqiad1::keystone::wiki_consumer_token'),
    $wiki_consumer_secret = hiera('profile::openstack::eqiad1::keystone::wiki_consumer_secret'),
    $wiki_access_token = hiera('profile::openstack::eqiad1::keystone::wiki_access_token'),
    $wiki_access_secret = hiera('profile::openstack::eqiad1::keystone::wiki_access_secret'),
    $labs_hosts_range = hiera('profile::openstack::eqiad1::labs_hosts_range'),
    $labs_hosts_range_v6 = hiera('profile::openstack::eqiad1::labs_hosts_range_v6'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::eqiad1::designate_hosts'),
    $labweb_hosts = hiera('profile::openstack::eqiad1::labweb_hosts'),
    $puppetmaster_hostname = hiera('profile::openstack::eqiad1::puppetmaster_hostname'),
    $auth_port = hiera('profile::openstack::base::keystone::auth_port'),
    $public_port = hiera('profile::openstack::base::keystone::public_port'),
    Boolean $daemon_active = lookup('profile::openstack::eqiad1::keystone::daemon_active'),
    String $wsgi_server = lookup('profile::openstack::eqiad1::keystone::wsgi_server'),
    Stdlib::IP::Address::V4::CIDR $instance_ip_range = lookup('profile::openstack::eqiad1::keystone::instance_ip_range', {default_value => '0.0.0.0/0'}),
    String $wmcloud_domain_owner = lookup('profile::openstack::eqiad1::keystone::wmcloud_domain_owner'),
    String $bastion_project_id = lookup('profile::openstack::eqiad1::keystone::bastion_project_id'),
    ) {

    require ::profile::openstack::eqiad1::clientpackages
    class {'::profile::openstack::base::keystone::service':
        daemon_active               => $daemon_active,
        version                     => $version,
        region                      => $region,
        openstack_controllers       => $openstack_controllers,
        keystone_host               => $keystone_host,
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
        labs_hosts_range            => $labs_hosts_range,
        labs_hosts_range_v6         => $labs_hosts_range_v6,
        designate_hosts             => $designate_hosts,
        labweb_hosts                => $labweb_hosts,
        wsgi_server                 => $wsgi_server,
        instance_ip_range           => $instance_ip_range,
        wmcloud_domain_owner        => $wmcloud_domain_owner,
        bastion_project_id          => $bastion_project_id,
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
        contact_groups => 'wmcs-team',
    }
    contain '::openstack::keystone::monitor::services'

    class {'::openstack::monitor::spreadcheck':
    }

    # monitor projects and users only on the controller servicing the
    # primary endpoints
    class {'::openstack::keystone::monitor::projects_and_users':
        active         => $::ipaddress == ipresolve($keystone_host,4),
        contact_groups => 'wmcs-team-email,admins',
    }
    contain '::openstack::keystone::monitor::projects_and_users'

    # allow foreign designate(and co) to call back to admin auth port
    # to validate issued tokens
    ferm::rule{'main_designate_35357':
        ensure => 'present',
        rule   => "saddr @resolve((${join($designate_hosts,' ')})) proto tcp dport (35357) ACCEPT;",
    }

    file { '/etc/cron.hourly/keystone':
        ensure => absent,
    }
}
