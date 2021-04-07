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
# [*password_mapping*]
#   Hash of sqlalchemy URIs to passwords.  This will be used
#   for the SQLALCHEMY_CUSTOM_PASSWORD_STORE, to allow for
#   passwords to external databases to be provided via configuration,
#   rather than the web UI.
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
# [*cache_uri*]
#   If set, used to configure the superset cache.
#   Multiple backends are available but only memcached is supported here.

class profile::superset(
    Integer $workers                    = lookup('profile::superset::workers', { 'default_value' => 1 }),
    String $database_uri                = lookup('profile::superset::database_uri', { 'default_value' => 'sqlite:////var/lib/superset/superset.db' }),
    Optional[String] $database_password = lookup('profile::superset::database_password', { 'default_value' => undef }),
    String $admin_user                  = lookup('profile::superset::admin_user', { 'default_value' => 'admin' }),
    String $admin_password              = lookup('profile::superset::admin_password', { 'default_value' => 'admin' }),
    String $secret_key                  = lookup('profile::superset::secret_key', { 'default_value' => 'not_really_a_secret_key' }),
    Boolean $ldap_proxy_enabled         = lookup('profile::superset::ldap_proxy_enabled', { 'default_value' => false }),
    Optional[String] $statsd            = lookup('statsd', { 'default_value' => undef }),
    String $gunicorn_app                = lookup('profile::superset::gunicorn_app', { 'default_value' => 'superset.app:create_app()' }),
    Boolean $enable_cas                 = lookup('profile::superset::enable_cas'),
    Optional[String] $cache_uri         = lookup('profile::superset::cache_uri', { 'default_value' => undef })
) {

    require_package('libmariadb3')

    # If given $database_password, insert it into $database_uri.
    $full_database_uri = $database_password ? {
        undef   => $database_uri,
        default => regsubst($database_uri, '(\w+)://(\w*)@(.*)', "\\1://\\2:${database_password}@\\3")
    }

    if $ldap_proxy_enabled {
        # Include the Superset HTTP WMF LDAP auth proxy
        include ::profile::superset::proxy

        # Use AUTH_REMOTE_USER if we are using
        # LDAP authenticated HTTP proxy.
        $auth_type = 'AUTH_REMOTE_USER'
        # Allow authenticated users (via ldap) to auto register
        # for superset in the 'Alpha' role.
        $auth_settings = {
            'AUTH_USER_REGISTRATION'        => 'True',
            'AUTH_USER_REGISTRATION_ROLE'   => 'Alpha',
        }
    }
    else {
        $auth_type = undef
        $auth_settings = undef
    }

    if $::realm == 'production' {
        # Use MySQL research user to access mysql DBs.
        include ::passwords::mysql::research
        $password_mapping = {
            # MediaWiki analytics slave database.
            "mysql://${::passwords::mysql::research::user}@analytics-store.eqiad.wmnet" =>
                $::passwords::mysql::research::pass,
            # EventLogging mysql slave database.
            "mysql://${::passwords::mysql::research::user}@analytics-slave.eqiad.wmnet/log" =>
                $::passwords::mysql::research::pass,
            # new cluster, staging
            "mysql://${::passwords::mysql::research::user}@staging-db-analytics.eqiad.wmnet:3350/staging" =>
                $::passwords::mysql::research::pass,
            # new cluster, wikishared
            "mysql://${::passwords::mysql::research::user}@dbstore1005.eqiad.wmnet:3320/wikishared" =>
                $::passwords::mysql::research::pass,
        }
    }
    else {
        $password_mapping = undef
    }

    class { '::superset':
        workers          => $workers,
        worker_class     => 'gevent',
        database_uri     => $full_database_uri,
        secret_key       => $secret_key,
        admin_user       => $admin_user,
        admin_password   => $admin_password,
        auth_type        => $auth_type,
        auth_settings    => $auth_settings,
        password_mapping => $password_mapping,
        statsd           => $statsd,
        gunicorn_app     => $gunicorn_app,
        enable_cas       => $enable_cas,
        cache_uri        => $cache_uri,
    }

    monitoring::service { 'superset':
        description   => 'superset',
        check_command => "check_tcp!${::superset::port}",
        require       => Class['::superset'],
        contact_group => 'victorops-analytics',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Superset',
    }

}
