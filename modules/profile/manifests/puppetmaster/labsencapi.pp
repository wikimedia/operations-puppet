# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class profile::puppetmaster::labsencapi(
    $mysql_host = hiera('profile::puppetmaster::labsencapi::mysql_host'),
    $mysql_db = hiera('profile::puppetmaster::labsencapi::mysql_db'),
    $mysql_username = hiera('profile::puppetmaster::labsencapi::mysql_username'),
    $statsd_host = hiera('profile::puppetmaster::labsencapi::statsd_host'),
    $statsd_prefix = hiera('profile::puppetmaster::labsencapi::statsd_prefix'),
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
