# (stat1002)
class role::statistics::private inherits role::statistics::base {
    system::role { 'role::statistics::private':
        description => 'Statistics private data host and general compute node'
    }

    include role::backup::host
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

    # kafkatee is useful here for adhoc processing of kafkadata
    require_package('kafkatee')

    # Although it is in the "private" role, the dataset actually isn't
    # private. We just keep it here to spare adding a separate role.
    include ::statistics::aggregator::projectview

    include passwords::mysql::research
    # This file will render at
    # /etc/mysql/conf.d/statistics-private-client.cnf.
    # This is so that users in the statistics-privatedata-users
    # group who want to access the research slave dbs do not
    # have to be in the research group, which is not included
    # in the private role (stat1002).
    mysql::config::client { 'statistics-private':
        user  => $::passwords::mysql::research::user,
        pass  => $::passwords::mysql::research::pass,
        group => 'statistics-privatedata-users',
        mode  => '0440',
    }

    # Set up reportupdater to be executed on this machine.
    # Reportupdater on stat1002 launches Hadoop jobs, and
    # the 'hdfs' user is the only 'system' user that has
    # access to required files in Hadoop.
    class { 'reportupdater':
        base_path => "${::statistics::working_path}/reportupdater",
        user      => 'hdfs',
        # We know that this is included on stat1002, but unfortunetly
        # it is done so outside of this role.  Perhaps
        # reportupdater should have its own role!
        require   => Class['cdh::hadoop'],
    }
    # And set up a link for periodic jobs to be included in published reports.
    # Because periodic is in published_datasets_path, files will be synced to
    # analytics.wikimedia.org/datasets/periodic/reports
    file { "${::statistics::compute::published_datasets_path}/periodic":
        ensure => 'directory',
        owner  => 'root',
        group  => 'wikidev',
        mode   => '0775',
    }
    file { "${::statistics::compute::published_datasets_path}/periodic/reports":
        ensure  => 'link',
        target  => "${::statistics::working_path}/reportupdater/output",
        require => Class['reportupdater'],
    }

    # Set up a job to create browser reports on hive db.
    reportupdater::job { 'browser':
        repository => 'reportupdater-queries',
        output_dir => 'metrics/browser',
    }
}
