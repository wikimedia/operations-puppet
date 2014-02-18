# Class: statistics::mobile_data_sync
#
# Sets up daily cron jobs to run a script which
# generates csv datafiles from mobile apps statistics
# then rsyncs those files to stat1001 so they can be served publicly
class statistics::mobile_data_sync {
    include passwords::mysql::research

    $source_dir        = '/a/limn-mobile-data'
    $command           = "${source_dir}/generate.py"
    $config            = "${source_dir}/mobile/"
    $mysql_credentials = '/a/.my.cnf.research'
    $rsync_from        = '/a/limn-public-data'
    $output            = "${rsync_from}/mobile/datafiles"
    $gerrit_repo       =
'https://gerrit.wikimedia.org/r/p/analytics/limn-mobile-data.git'
    $user              = $statistics::username

    $db_user           = $passwords::mysql::research::user
    $db_pass           = $passwords::mysql::research::pass

    git::clone { 'analytics/limn-mobile-data':
        ensure    => 'latest',
        directory => $source_dir,
        origin    => $gerrit_repo,
        owner     => $user,
        require   => [User[$user]],
    }

    file { $mysql_credentials:
        owner   => $user,
        group   => $user,
        mode    => '0600',
        content => template('statistics/mysql-config-research.erb'),
    }

    file { $output:
        ensure => 'directory',
        owner  => $user,
        group  => 'wikidev',
        mode   => '0775',
    }

    cron { 'rsync_mobile_apps_stats':
        command => "python ${command} ${config} && /usr/bin/rsync -rt ${rsync_from}/* stat1001.wikimedia.org::www/limn-public-data/",
        user    => $user,
        minute  => 0,
    }
}
