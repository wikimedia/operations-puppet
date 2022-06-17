class openstack::keystone::service::victoria(
    $controller_hosts,
    $osm_host,
    $db_name,
    $db_user,
    $db_pass,
    $db_host,
    $db_max_pool_size,
    $public_workers,
    $admin_workers,
    $ldap_hosts,
    $ldap_rw_host,
    $ldap_base_dn,
    $ldap_user_id_attribute,
    $ldap_user_name_attribute,
    $ldap_user_dn,
    $ldap_user_pass,
    $region,
    String $keystone_admin_uri,
    $wiki_status_page_prefix,
    $wiki_status_consumer_token,
    $wiki_status_consumer_secret,
    $wiki_status_access_token,
    $wiki_status_access_secret,
    $wiki_consumer_token,
    $wiki_consumer_secret,
    $wiki_access_token,
    $wiki_access_secret,
    String $wsgi_server,
    Stdlib::IP::Address::V4::CIDR $instance_ip_range,
    String $wmcloud_domain_owner,
    String $bastion_project_id,
    Array[String] $prod_networks,
    Array[String] $labs_networks,
    Boolean $enforce_policy_scope,
    Boolean $enforce_new_policy_defaults,
    Stdlib::Port $public_bind_port,
    Stdlib::Port $admin_bind_port,
    Array[Stdlib::IP::Address::V4::Nosubnet] $prometheus_metricsinfra_reserved_ips,
    Array[Stdlib::Port] $prometheus_metricsinfra_default_ports,
) {
    class { "openstack::keystone::service::victoria::${::lsbdistcodename}":
        public_bind_port => $public_bind_port,
        admin_bind_port  => $admin_bind_port,
    }

    # Fernet key count.  We rotate once per day on each host.  That means that
    #  for our keys to live a week, we need at least 7*(number of hosts) keys
    #  at any one time.  Using 9 here instead because it costs us nothing
    #  and provides ample slack.
    $max_active_keys = $controller_hosts.length * 9

    file {
        '/etc/logrotate.d/keystone':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/victoria/keystone/keystone_logrotate',
            require => Package['keystone'];
        '/etc/keystone/keystone.conf':
            ensure    => 'present',
            owner     => 'keystone',
            group     => 'keystone',
            mode      => '0444',
            show_diff => false,
            content   => template('openstack/victoria/keystone/keystone.conf.erb'),
            notify    => Service[$wsgi_server],
            require   => Package['keystone'];
        '/etc/keystone/keystone-paste.ini':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/victoria/keystone/keystone-paste.ini',
            notify  => Service[$wsgi_server],
            require => Package['keystone'];
        '/etc/keystone/policy.yaml':
            ensure  => 'present',
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///modules/openstack/victoria/keystone/policy.yaml',
            notify  => Service[$wsgi_server],
            require => Package['keystone'];
        '/etc/keystone/logging.conf':
            ensure  => 'present',
            source  => 'puppet:///modules/openstack/victoria/keystone/logging.conf',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service[$wsgi_server],
            require => Package['keystone'];
        '/etc/keystone/keystone.my.cnf':
            ensure    => 'present',
            owner     => 'root',
            group     => 'root',
            mode      => '0400',
            show_diff => false,
            content   => template('openstack/victoria/keystone/keystone.my.cnf.erb');
        '/usr/lib/python3/dist-packages/wmfkeystoneauth':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/victoria/keystone/wmfkeystoneauth',
            notify  => Service[$wsgi_server],
            recurse => true;
        '/usr/lib/python3/dist-packages/wmfkeystoneauth.egg-info':
            ensure  => 'present',
            source  => 'puppet:///modules/openstack/victoria/keystone/wmfkeystoneauth.egg-info',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service[$wsgi_server],
            recurse => true;
        '/usr/lib/python3/dist-packages/keystone/api/projects.py':
            # This is the same as the upstream Stein projects.py, with one line added.
            #  that line is there to ensure that project_id == project_name
            ensure => 'present',
            source => 'puppet:///modules/openstack/victoria/keystone/projects.py',
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            notify => Service[$wsgi_server],
    }
}
