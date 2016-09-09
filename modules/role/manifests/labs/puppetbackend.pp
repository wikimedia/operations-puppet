# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::labs::puppetbackend(
    $mysql_host,
    $mysql_db = 'labspuppet',
    $mysql_username = 'labspuppet',
    $mysql_password = 'labspuppet',
    $statsd_host = 'labmon1001.eqiad.wmnet',
    $statsd_prefix = 'labs.puppetbackend',
) {
    class { '::labspuppetbackend':
        mysql_host     => $mysql_host,
        mysql_db       => $mysql_db,
        mysql_username => $mysql_username,
        mysql_password => $mysql_password,
        statsd_host    => $statsd_host,
        statsd_prefix  => $statsd_prefix,
    }
}
