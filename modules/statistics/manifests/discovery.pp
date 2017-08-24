# = Class: statistics::discovery
#
# NOTE:  This class includes the statistics::discovery::user class, which ensures that
# the discovery-stats user is in the analytics-privatedata-users group.  This means
# that you CANNOT include statistics::discovery somewhere that does not have the
# analytics-privatedata-users present.
#
class statistics::discovery {
    Class['::statistics'] -> Class['::statistics::discovery']

    include ::passwords::mysql::research
    include ::statistics::discovery::user

    $working_path = $::statistics::working_path
    # Homedir for everything Wikimedia Discovery Analytics related
    $dir = "${working_path}/discovery"
    # Path in which daily runs will log to
    $log_dir = "${dir}/log"
    # Path in which the R library will reside
    $rlib_dir = "${dir}/r-library"


    $user = $::statistics::discovery::user::user
    $group = $::statistics::discovery::user::group

    # This file will render at
    # /etc/mysql/conf.d/discovery-stats-client.cnf.
    ::mysql::config::client { $user:
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
        mode   => '0775', # so Discovery's Analysts (as members of analytics-privatedata-users group) can read, write, execute
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
        command => "cd ${dir}/golden && sh main.sh >> ${log_dir}/golden-daily.log 2>&1",
        hour    => '5',
        minute  => '0',
        require => [
            Class['::statistics::compute'],
            Git::Clone['wikimedia/discovery/golden'],
            Mysql::Config::Client[$user]
        ],
        user    => $user,
    }

}
