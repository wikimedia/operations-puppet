# == Class profile::statistics::private
#
class profile::statistics::private(
    $statistics_servers = hiera('statistics_servers'),
) {
    include ::standard
    # Can't include base firewall on statistics private boxes.
    # Hadoop clients (like spark) can start up CLIs that interact
    # with Hadoop via ephemeral ports.
    class { '::base::firewall':
        ensure => 'absent'
    }

    include ::deployment::umask_wikidev

    include ::profile::backup::host
    backup::set { 'home' : }

    class { '::statistics':
        servers      => $statistics_servers,
    }

    # include stuff common to statistics compute nodes
    include ::statistics::compute

    # This file will render at
    # /etc/mysql/conf.d/statistics-private-client.cnf.
    # This is so that users in the statistics-privatedata-users
    # group who want to access the research slave dbs do not
    # have to be in the research group, which is not included
    # in the private role.
    statistics::mysql_credentials { 'statistics-private':
        group => 'statistics-privatedata-users',
    }

    # Include the MySQL research password at
    # /etc/mysql/conf.d/analytics-research-client.cnf
    # and only readable by users in the
    # analytics-privatedata-users group.
    statistics::mysql_credentials { 'analytics-research':
        group => 'analytics-privatedata-users',
    }

    # The eventlogging codebase is useful for scripting
    # EventLogging consumers.  Install this on
    # stat1002, but don't run any daemons.
    include ::eventlogging

    # EventLogging Analytics data logs are not private, but they
    # are rsynced here for convenience and backup redundancy.
    include ::statistics::rsync::eventlogging

    # rsync mediawiki logs from logging hosts
    include ::statistics::rsync::mediawiki

    # TODO: Piecemeal migrate cron jobs from stat1002 -> stat1005: T152712
    if $::hostname == 'stat1002' {
        # TODO: Otto believes this data and job are no longer being used.
        # Let's not migrate it to stat1005 unless someone needs it.
        # Although it is in the "private" profile, the dataset actually isn't
        # private. We just keep it here to spare adding a separate role.
        include ::statistics::aggregator::projectview

        # Discovery statistics generating scripts
        include ::statistics::discovery
    }

    # Else moved to stat1005
    else {
        # backup eventlogging logs.
        backup::set { 'srv-log-eventlogging' : }

        # WMDE statistics scripts and cron jobs
        include ::statistics::wmde
    }
}
