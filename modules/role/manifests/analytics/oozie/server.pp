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
    # Package['mysql-server'] -> Class['cdh::oozie::database::mysql']

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

    # Oozie is creating event logs in /var/log/oozie.
    # It rotates them but does not delete old ones.  Set up cronjob to
    # delete old files in this directory.
    cron { 'oozie-clean-logs':
        command => 'test -d /var/log/oozie && /usr/bin/find /var/log/oozie -type f -mtime +62 -exec rm {} >/dev/null \;',
        minute  => 5,
        hour    => 0,
        require => Class['cdh::oozie::server'],
    }

    ferm::service{ 'oozie_server':
        proto  => 'tcp',
        port   => '11000',
        srange => '$INTERNAL',
    }
}
