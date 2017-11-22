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
# [*statsd*]
#   statsd host:port
#
class profile::superset(
    $database_uri      = hiera('profile::superset::database_uri', 'sqlite:////var/lib/superset/superset.db'),
    $database_password = hiera('profile::superset::database_password', undef),
    $admin_user        = hiera('profile::superset::admin_user', 'admin'),
    $admin_pass        = hiera('profile::superset::admin_pass', 'admin'),
    $secret_key        = hiera('profile::superset::secret_key', 'not_really_a_secret_key'),
    $password_mapping  = hiera('profile::superset::password_mapping', undef),
    $statsd            = hiera('statsd', undef),
) {
    # If given $database_password, insert it into $database_uri.
    $_database_uri = $database_password ? {
        undef   => $database_uri,
        default => regsubst($database_uri, '(\w+)://(\w*)@(.*)', "\1://\2:${database_password}@\3")
    }

    class { '::superset':
        database_uri     => $_database_uri,
        secret_key       => $secret_key,
        admin_user       => $admin_user,
        admin_password   => $admin_password,
        password_mapping => $password_mapping,
        statsd           => $statsd,
    }
}
