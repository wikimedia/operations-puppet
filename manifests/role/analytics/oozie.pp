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
        # This is not currently working.  Disabling
        # this allows any user to manage any Oozie
        # job.  Since access to our cluster is limited,
        # this isn't a big deal.  But, we should still
        # figure out why this isn't working and
        # turn it back on.
        # I was not able to kill any oozie jobs
        # with this on, even though the
        # oozie.service.ProxyUserService.proxyuser.*
        # settings look like they are properly configured.
        authorization_service_authorization_enabled => false,
    }
}
