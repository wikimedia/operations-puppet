# == Class role::analytics::oozie::client
# Installs oozie client, which sets up the OOZIE_URL
# environment variable.  If you are using this class in
# Labs, you must include oozie::server on your primary
# Hadoop NameNode for this to work and set appropriate
# Labs Hadoop global parameters.
# See role/analytics/hadoop.pp documentation for more info.


# == Class role::analytics::oozie::config
#
class role::analytics::oozie::config {
    include role::analytics::hadoop::config

    if $::realm == 'production' {
        $oozie_host      = 'analytics1027.eqiad.wmnet'
        $jdbc_password   = $passwords::analytics::oozie_jdbc_password
    }
    elsif $::realm == 'labs' {
        $oozie_host      = $role::analytics::hadoop::config::namenode_hosts[0]
        $jdbc_password   = 'oozie'
    }
}


# == Class role::analytics::oozie::client
# Installs Oozie client.
#
class role::analytics::oozie::client inherits role::analytics::oozie::config {
    require role::analytics::hadoop::client

    class { 'cdh::oozie':
        oozie_host => $oozie_host,
    }
}

# == Class role::analytics::oozie::server
# Installs Oozie server backed by a MySQL database.
#
class role::analytics::oozie::server inherits role::analytics::oozie::client {
    if (!defined(Package['mysql-server'])) {
        package { 'mysql-server':
            ensure => 'installed',
        }
    }
    # Make sure mysql-server is installed before
    # MySQL Oozie database class is applied.
    Package['mysql-server'] -> Class['cdh::oozie::database::mysql']

    class { 'cdh::oozie::server':
        jdbc_password   => $jdbc_password,
        smtp_host       => $::mail_smarthost[0],
        smtp_from_email => "oozie@${::fqdn}",
    }
}
