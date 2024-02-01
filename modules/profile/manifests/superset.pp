# SPDX-License-Identifier: Apache-2.0
# == Class profile::superset
# Sets up superset site.
#
# == Parameters
#
# [*database_uri*]
#   SQL Alchemy database URI to use as the superset state store.
#   This can be a passwordless URI if $database_password is provided.
#
# [*database_password*]
#   If given, it will be inserted into the $database_uri.  This expects that $database_uri
#   is of the form 'protocol://username@hostname/databasename'.
#
# [*admin_user*]
#   Web UI admin user
#
# [*admin_password*]
#   Web UI admin user password

# [*secret_key*]
#   flask secret key
#
# [*ldap_proxy_enabled*]
#   If true, an Apache HTTP proxy will be configured to authenticate users with WMF (labs) LDAP.
#   Only users in the 'wmf' and 'nda' LDAP groups will be allowed to authenticate.
#   This will configure superset with AUTH_TYPE = AUTH_REMOTE_USER, and the authenticated
#   HTTP remote user will be used to log into superset.
#
# [*statsd*]
#   statsd host:port
#
# [*metadata_cache_uri*]
#   If set, this is used to configure the superset metadata cache.
#   Multiple backends are available but only memcached is supported here.
#
# [*data_cache_uri*]
#   If set, this is used to configure the superset data cache with the results of queries.
#   Multiple backends are available but only memcached is supported here.
#
# [*filter_state_cache_uri*]
#   This is a key-value endpoint to store dashboard filter state. It should be specified from version 1.5.0 onwards.
#   Multiple backends are available but only memcached is supported here.
#
# [*explore_form_data_cache_uri*]
#   This is a key value endpoint to store the explore form data. It should be specified from version 1.5.0 onwards.
#   Multiple backends are available but only memcached is supported here.
#
# [*workers*]
#   Number of gevent workers
#
# [*gunicorn_app*]
#   In Superset 0.36.0+ gunicorn needs a different appname for
#   Superset. Default is still for older releases, up to 0.35.x
#   Default: 'superset.app'
#
# [*enable_cas*]
#   Enable authentication via CAS instead of LDAP

class profile::superset (
    Integer $workers                              = lookup('profile::superset::workers', { 'default_value' => 1 }),
    String $database_uri                          = lookup('profile::superset::database_uri', { 'default_value' => 'sqlite:////var/lib/superset/superset.db' }),
    Optional[String] $database_password           = lookup('profile::superset::database_password', { 'default_value' => undef }),
    String $admin_user                            = lookup('profile::superset::admin_user', { 'default_value' => 'admin' }),
    String $admin_password                        = lookup('profile::superset::admin_password', { 'default_value' => 'admin' }),
    String $secret_key                            = lookup('profile::superset::secret_key', { 'default_value' => 'not_really_a_secret_key' }),
    Boolean $ldap_proxy_enabled                   = lookup('profile::superset::ldap_proxy_enabled', { 'default_value' => false }),
    Optional[String] $statsd                      = lookup('profile::superset::statsd', { 'default_value' => undef }),
    String $gunicorn_app                          = lookup('profile::superset::gunicorn_app', { 'default_value' => 'superset.app:create_app()' }),
    Boolean $enable_cas                           = lookup('profile::superset::enable_cas'),
    Boolean $enable_presto_nested_data            = lookup('profile::superset::enable_presto_nested_data', { 'default_value' => true }),
    Optional[String] $metadata_cache_uri          = lookup('profile::superset::metadata_cache_uri', { 'default_value' => undef }),
    Optional[String] $data_cache_uri              = lookup('profile::superset::data_cache_uri', { 'default_value' => undef }),
    Optional[String] $filter_state_cache_uri      = lookup('profile::superset::filter_state_cache_uri', { 'default_value' => undef }),
    Optional[String] $explore_form_data_cache_uri = lookup('profile::superset::explore_form_data_cache_uri', { 'default_value' => undef })
) {
    ensure_packages('libmariadb3')

    # If given $database_password, insert it into $database_uri.
    $full_database_uri = $database_password ? {
        undef   => $database_uri,
        default => regsubst($database_uri, '(\w+)://(\w*)@(.*)', "\\1://\\2:${database_password}@\\3")
    }

    if $ldap_proxy_enabled {
        # Include the Superset HTTP WMF LDAP auth proxy
        include profile::superset::proxy

        # Use AUTH_REMOTE_USER if we are using
        # LDAP authenticated HTTP proxy.
        $auth_type = 'AUTH_REMOTE_USER'
        # Allow authenticated users (via ldap) to auto register
        # for superset in the 'Alpha' role.
        $auth_settings = {
            'AUTH_USER_REGISTRATION'        => 'True',
            'AUTH_USER_REGISTRATION_ROLE'   => 'WMF Analyst',
        }
    }
    else {
        $auth_type = undef
        $auth_settings = undef
    }

    if $::realm == 'production' {
        # Use MySQL research user to access mysql DBs.
        include passwords::mysql::research
        $password_mapping = {
            # MediaWiki analytics slave database.
            "mysql://${passwords::mysql::research::user}@analytics-store.eqiad.wmnet" =>
                $passwords::mysql::research::pass,
            # EventLogging mysql slave database.
            "mysql://${passwords::mysql::research::user}@analytics-slave.eqiad.wmnet/log" =>
                $passwords::mysql::research::pass,
            # new cluster, staging
            "mysql://${passwords::mysql::research::user}@staging-db-analytics.eqiad.wmnet:3350/staging" =>
                $passwords::mysql::research::pass,
            # new cluster, wikishared
            "mysql://${passwords::mysql::research::user}@dbstore1009.eqiad.wmnet:3320/wikishared" =>
                $passwords::mysql::research::pass,
        }
    }
    else {
        $password_mapping = undef
    }

    class { 'superset':
        workers                     => $workers,
        worker_class                => 'gevent',
        database_uri                => $full_database_uri,
        secret_key                  => $secret_key,
        admin_user                  => $admin_user,
        admin_password              => $admin_password,
        auth_type                   => $auth_type,
        auth_settings               => $auth_settings,
        password_mapping            => $password_mapping,
        statsd                      => $statsd,
        gunicorn_app                => $gunicorn_app,
        enable_cas                  => $enable_cas,
        enable_presto_nested_data   => $enable_presto_nested_data,
        metadata_cache_uri          => $metadata_cache_uri,
        data_cache_uri              => $data_cache_uri,
        filter_state_cache_uri      => $filter_state_cache_uri,
        explore_form_data_cache_uri => $explore_form_data_cache_uri,
    }

    class { 'profile::prometheus::statsd_exporter':
        enable_scraping => false,
    }

    monitoring::service { 'superset':
        description   => 'superset',
        check_command => "check_tcp!${superset::port}",
        require       => Class['superset'],
        contact_group => 'victorops-analytics',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Superset',
    }

    file { '/usr/local/bin/check_superset_http':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/superset/check_superset_http.sh',
    }

    if $enable_cas {
        $user_header = 'X-Cas-Uid'
    } else {
        $user_header = 'X-Remote-User'
    }

    nrpe::monitor_service { 'check_superset_http':
        nrpe_command  => "/usr/local/bin/check_superset_http ${user_header}",
        description   => 'Check that superset http server is responding ok',
        require       => File['/usr/local/bin/check_superset_http'],
        contact_group => 'victorops-analytics',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Superset',
    }
}
