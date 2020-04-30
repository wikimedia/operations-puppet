# == Class profile::statistics::private
#
class profile::statistics::private(
    $labstore_hosts      = hiera('labstore_hosts'),
) {

    include ::profile::statistics::base

    class {'::deployment::umask_wikidev': }

    # Directory to host datasets that are generated locally and synced over
    # via rsync fetch jobs running on the dumps distribution servers
    file {'/srv/dumps':
        ensure => 'directory',
        mode   => '0775',
        owner  => 'stats',
        group  => 'wikidev',
    }

    # Include the MySQL research password at
    # /etc/mysql/conf.d/analytics-research-client.cnf
    # and only readable by users in the
    # analytics-privatedata-users group.
    statistics::mysql_credentials { 'analytics-research':
        group => 'analytics-privatedata-users',
    }

    # The eventlogging codebase is useful for scripting
    # EventLogging consumers.  Install this but don't run any daemons.
    class { '::eventlogging': }
}
