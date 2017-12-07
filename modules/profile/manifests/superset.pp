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
class profile::superset(
    $workers           = hiera('profile::superset::workers', 1),
    $database_uri      = hiera('profile::superset::database_uri', 'sqlite:////var/lib/superset/superset.db'),
    $database_password = hiera('profile::superset::database_password', undef),
    $admin_user        = hiera('profile::superset::admin_user', 'admin'),
    $admin_password    = hiera('profile::superset::admin_password', 'admin'),
    $secret_key        = hiera('profile::superset::secret_key', 'not_really_a_secret_key'),
    $password_mapping  = hiera('profile::superset::password_mapping', undef),
    $ldap_proxy_enabled = hiera('profile::superset::ldap_proxy_enabled', false),
    $statsd            = hiera('statsd', undef),
) {
    # If given $database_password, insert it into $database_uri.
    $full_database_uri = $database_password ? {
        undef   => $database_uri,
        default => regsubst($database_uri, '(\w+)://(\w*)@(.*)', "\\1://\\2:${database_password}@\\3")
    }

    if $ldap_proxy_enabled {
        # Include the Superset HTTP WMF LDAP auth proxy
        class { '::superset::proxy': }

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

    class { '::superset':
        workers          => $workers,
        database_uri     => $full_database_uri,
        secret_key       => $secret_key,
        admin_user       => $admin_user,
        admin_password   => $admin_password,
        auth_type        => $auth_type,
        auth_settings    => $auth_settings,
        password_mapping => $password_mapping,
        statsd           => $statsd,
    }

    monitoring::service { 'superset':
        description   => 'superset',
        check_command => "check_tcp!${::superset::port}",
        require       => Class['::superset'],
    }

}
