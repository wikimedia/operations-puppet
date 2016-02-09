# Licence AGPL version 3 or later
#
# Module for running WMDE releated analytics scripts
class wmde_analytics(
    $user = 'wmde-analytics'
) {

    require_package(
        #TODO JAVA runtime!
        'php5',
        'php5-cli',
        'git')

    group { $user:
        ensure => present,
        name   => $user,
    }

    user { $user:
        ensure     => present,
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    git::clone { 'wmde/scripts':
        ensure    => 'latest',
        directory => "/home/${$user}/git/scripts",
        origin    => 'git clone git clone https://gerrit.wikimedia.org/r/analytics/wmde/scripts',
        owner     => $user,
        group     => $user,
        require => User[$user],
    }

    git::clone { 'wmde/toolkit-analyzer-build':
        ensure    => 'latest',
        directory => "/home/${$user}/git/toolkit-analyzer-build",
        origin    => 'git clone https://gerrit.wikimedia.org/r/analytics/wmde/toolkit-analyzer-build',
        owner     => $user,
        group     => $user,
        require => User[$user],
    }

    #TODO add some sort of logrotate?
    cron { 'minutely':
        ensure  => present,
        command => "/home/${$user}/git/scripts/minutely.sh >> /home/${$user}/log/minutely.log 2>&1",
        user    => $user,
        hour    => '*',
        minute  => '*',
        require => Git::Clone['wmde/scripts'],
    }

    #TODO cron for daily_datamodel
    #TODO cron for daily graphite/entityUsage
    #TODO cron for daily_social
    #TODO cron for daily_misc
    #TODO cron for daily_site_stats
    #TODO cron for daily api log scanner
    #TODO cron for weekly JAR log scan

}
