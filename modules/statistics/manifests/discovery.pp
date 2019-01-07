# = Class: statistics::discovery
# Maintainer: Mikhail Popov (bearloga)
class statistics::discovery {
    Class['::statistics'] -> Class['::statistics::discovery']

    include ::passwords::mysql::research

    $working_path = $::statistics::working_path
    # Homedir for everything Search Platform (formerly Discovery) related
    $dir = "${working_path}/discovery"
    # Path in which daily runs will log to
    $log_dir = "${dir}/log"
    # Path in which the R library will reside
    $rlib_dir = "${dir}/r-library"

    $user = 'analytics-search'
    # Setting group to 'analytics-privatedata-users' so that Discovery's Analysts
    # (as members of analytics-privatedata-users) have some privileges, and so
    # the user can access private data in Hive. Also refer to T174110#4265908.
    $group ='analytics-privatedata-users'

    # This file will render at
    # /etc/mysql/conf.d/discovery-stats-client.cnf.
    ::mariadb::config::client { 'discovery-stats':
        user  => $::passwords::mysql::research::user,
        pass  => $::passwords::mysql::research::pass,
        group => $group,
        mode  => '0440',
    }

    $directories = [
        $dir,
        $log_dir,
        $rlib_dir
    ]

    file { $directories:
        ensure => 'directory',
        owner  => $user,
        group  => $group,
        mode   => '0775',
    }

    git::clone { 'wikimedia/discovery/golden':
        ensure             => 'latest',
        branch             => 'master',
        recurse_submodules => true,
        directory          => "${dir}/golden",
        owner              => $user,
        group              => $group,
        require            => File[$dir],
    }

    logrotate::conf { 'wikimedia-discovery-stats':
        ensure  => present,
        content => template('statistics/discovery-stats.logrotate.erb'),
        require => File[$log_dir],
    }

    # Running the script at 5AM UTC means that:
    # - Remaining data from previous day is likely to have finished processing.
    # - It's ~9/10p Pacific time, so we're not likely to hinder people's work
    #   on analytics cluster, although we use `nice` & `ionice` as a courtesy.

    cron { 'wikimedia-discovery-golden':
        ensure  => present,
        command => "cd ${dir}/golden && sh main.sh >> ${log_dir}/golden-daily.log 2>&1",
        hour    => '5',
        minute  => '0',
        require => [
            Class['::statistics::compute'],
            Git::Clone['wikimedia/discovery/golden'],
            Mariadb::Config::Client['discovery-stats']
        ],
        user    => $user,
    }

}
