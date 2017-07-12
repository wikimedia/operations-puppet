# (stat1002)
class role::statistics::private inherits role::statistics::base {
    system::role { 'statistics::private':
        description => 'Statistics private data host and general compute node'
    }

    include ::profile::backup::host
    backup::set { 'home' : }

    # include stuff common to statistics compute nodes
    include ::statistics::compute

    # rsync mediawiki logs from logging hosts
    include ::statistics::rsync::mediawiki

    # WMDE statistics scripts and cron jobs
    include ::statistics::wmde

    # Discovery statistics generating scripts
    include ::statistics::discovery

    # eventlogging logs are not private, but they
    # are here for convenience
    include ::statistics::rsync::eventlogging
    # backup eventlogging logs
    backup::set { 'a-eventlogging' : }

    # Although it is in the "private" role, the dataset actually isn't
    # private. We just keep it here to spare adding a separate role.
    include ::statistics::aggregator::projectview

    # This file will render at
    # /etc/mysql/conf.d/statistics-private-client.cnf.
    # This is so that users in the statistics-privatedata-users
    # group who want to access the research slave dbs do not
    # have to be in the research group, which is not included
    # in the private role.
    statistics::mysql_credentials { 'statistics-private':
        group => 'statistics-privatedata-users',
    }

    # Run Hadoop/Hive reportupdater jobs here.
    include ::profile::reportupdater::jobs::hadoop
}
