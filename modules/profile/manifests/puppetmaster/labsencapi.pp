# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class profile::puppetmaster::labsencapi(
    $mysql_host,
    $mysql_db,
    $mysql_username,
    $statsd_host,
    $statsd_prefix,
    $mysql_password = hiera('labspuppetbackend_mysql_password'),
) {
    class { '::labspuppetbackend':
        mysql_host     => $mysql_host,
        mysql_db       => $mysql_db,
        mysql_username => $mysql_username,
        statsd_host    => $statsd_host,
        statsd_prefix  => $statsd_prefix,
        mysql_password => $mysql_password,
    }
}
