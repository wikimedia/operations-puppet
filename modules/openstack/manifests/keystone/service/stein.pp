class openstack::keystone::service::stein(
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
    $ldap_base_dn,
    $ldap_user_id_attribute,
    $ldap_user_name_attribute,
    $ldap_user_dn,
    $ldap_user_pass,
    $region,
    $auth_protocol,
    $auth_port,
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
) {
    class { "openstack::keystone::service::stein::${::lsbdistcodename}": }

    include ::network::constants
    $prod_networks = $network::constants::production_networks
    $labs_networks = $network::constants::labs_networks

    # This is a backport of https://review.opendev.org/#/c/665617/
    # Without this change we encounter a lot of encoding errors when validating fernet tokens.
    #
    # This patch was backported to upstream Stein so probably not needed in the next upgrade cycle.
    file { '/usr/lib/python3/dist-packages/keystone/token/token_formatters.py':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/stein/keystone/token_formatters-fixed.py',
            require => Package['keystone'];
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
            source  => 'puppet:///modules/openstack/stein/keystone/keystone_logrotate',
            require => Package['keystone'];
        '/etc/keystone/keystone.conf':
            ensure    => 'present',
            owner     => 'keystone',
            group     => 'keystone',
            mode      => '0444',
            show_diff => false,
            content   => template('openstack/stein/keystone/keystone.conf.erb'),
            notify    => Service[$wsgi_server],
            require   => Package['keystone'];
        '/etc/keystone/keystone-paste.ini':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/stein/keystone/keystone-paste.ini',
            notify  => Service[$wsgi_server],
            require => Package['keystone'];
        '/etc/keystone/policy.json':
            ensure  => 'absent';
        '/etc/keystone/policy.yaml':
            ensure  => 'present',
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///modules/openstack/stein/keystone/policy.yaml',
            notify  => Service[$wsgi_server],
            require => Package['keystone'];
        '/etc/keystone/logging.conf':
            ensure  => 'present',
            source  => 'puppet:///modules/openstack/stein/keystone/logging.conf',
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
            content   => template('openstack/stein/keystone/keystone.my.cnf.erb');
        '/usr/lib/python3/dist-packages/wmfkeystoneauth':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/stein/keystone/wmfkeystoneauth',
            notify  => Service[$wsgi_server],
            recurse => true;
        '/usr/lib/python3/dist-packages/wmfkeystoneauth.egg-info':
            ensure  => 'present',
            source  => 'puppet:///modules/openstack/stein/keystone/wmfkeystoneauth.egg-info',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service[$wsgi_server],
            recurse => true;
    }
}
