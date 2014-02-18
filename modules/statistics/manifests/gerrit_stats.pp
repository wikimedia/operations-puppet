# == Class misc::statistics::gerrit_stats
#
# Installs diederik's gerrit-stats python
# scripts, and sets a cron job to run it and
# to commit and push generated data into
# a repository.
#
class statistics::gerrit_stats {
    $gerrit_stats_repo_url      = 'https://gerrit.wikimedia.org/r/p/analytics/gerrit-stats.git'
    $gerrit_stats_data_repo_url = 'ssh://stats@gerrit.wikimedia.org:29418/analytics/gerrit-stats/data.git'
    $gerrit_stats_base          = '/a/gerrit-stats'
    $gerrit_stats_path          = "${gerrit_stats_base}/gerrit-stats"
    $gerrit_stats_data_path     = "${gerrit_stats_base}/data"


    # use the stats user
    $gerrit_stats_user          = $statistics::user::username
    $gerrit_stats_user_home     = $statistics::user::homedir

    file { $gerrit_stats_base:
        ensure => 'directory',
        owner  => $gerrit_stats_user,
        group  => 'wikidev',
        mode   => '0775',
    }



    # Clone the gerrit-stats and gerrit-stats/data
    # repositories into subdirs of $gerrit_stats_path.
    # This requires that the $gerrit_stats_user
    # has an ssh key that is allowed to clone
    # from git.less.ly.

    git::clone { 'gerrit-stats':
        ensure    => 'latest',
        directory => $gerrit_stats_path,
        origin    => $gerrit_stats_repo_url,
        owner     => $gerrit_stats_user,
        require   => [User[$gerrit_stats_user],
                      Class['statistics::packages']],
    }

    git::clone { 'gerrit-stats/data':
        ensure    => 'latest',
        directory => $gerrit_stats_data_path,
        origin    => $gerrit_stats_data_repo_url,
        owner     => $gerrit_stats_user,
        require   => User[$gerrit_stats_user],
    }

    # Make sure ~/.my.cnf is only readable by stats user.
    # The gerrit stats script requires this file to
    # connect to gerrit MySQL database.
    file { "${gerrit_stats_user_home}/.my.cnf":
        mode  => '0600',
        owner => 'stats',
        group => 'stats',
    }

    # Run a cron job from the $gerrit_stats_path.
    # This will create a $gerrit_stats_path/data
    # directory containing stats about gerrit.
    #
    # Note: gerrit-stats requires mysql access to
    # the gerrit stats database.  The mysql user creds
    # are configured in /home/$gerrit_stats_user/.my.cnf,
    # which is not puppetized in order to keep pw private.
    #
    # Once gerrit-stats has run, the newly generated
    # data in $gerrit_stats_path/data will be commited
    # and pushed to the gerrit-stats/data repository.
    cron { 'gerrit-stats-daily':
        ensure  => 'absent',
        command => "/usr/bin/python ${gerrit_stats_path}/gerritstats/stats.py --dataset ${gerrit_stats_data_path} --toolkit dygraphs --settings /a/gerrit-stats/gerrit-stats/gerritstats/settings.yaml >> ${gerrit_stats_base}/gerrit-stats.log && (cd ${gerrit_stats_data_path} && git add . && git commit -q -m \"Updating gerrit-stats data after gerrit-stats run at $(date)\" && git push -q)",
        user    => $gerrit_stats_user,
        hour    => '23',
        minute  => '59',
        require => [Git::Clone['gerrit-stats'],
                    Git::Clone['gerrit-stats/data'],
                    File["${gerrit_stats_user_home}/.my.cnf"]],
    }
}

