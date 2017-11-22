# == Class profile::superset
# Sets up superset site.
#
class profile::superset(
    $database_uri      = hiera('profile::superset::database_uri', 'sqlite:////tmp/superset.db'),
    $secret_key        = hiera('profile::superset::secret_key', 'thisismynotsecretkey'),
    $password_mapping  = hiera('profile::superset::password_mapping', undef),
    $statsd            = hiera('statsd', undef),
) {
    class { '::superset':
        database_uri     => $database_uri,
        secret_key       => $secret_key,
        password_mapping => $password_mapping,
        statsd           => $statsd,
    }
}
