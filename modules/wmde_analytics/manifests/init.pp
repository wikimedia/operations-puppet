# licence AGPL version 3 or later
class wmde_analytics {

    require_package(
        #TODO JAVA runtime!
        'php5',
        'php5-cli',
        'git')

    group { 'wmde-analytics':
        ensure => present,
    }

    user { 'wmde-analytics':
        ensure     => 'present',
        #QUESTION: Should this be in /home or somewhere else?
        #If we clones the things to other places then this home dir wouldn't even be needed?
        home       => '/home/wmde-analytics',
        managehome => true,
        gid    => 'wmde-analytics',
        system     => true,
    }

    git::clone { 'wmde/scripts':
        ensure    => 'latest',
        directory => '/home/wmde-analytics/git/scripts',
        #FIXME this repo doesn't exist yet! (https://www.mediawiki.org/wiki/Git/New_repositories/Requests)
        origin    => 'git clone https://addshore@gerrit.wikimedia.org/r/analytics/wmde/scripts',
        owner     => 'wmde-analytics',
        group     => 'wmde-analytics',
        require => User['wmde-analytics'],
    }

    git::clone { 'wmde/toolkit-analyzer-build':
        ensure    => 'latest',
        directory => '/home/wmde-analytics/git/toolkit-analyzer-build',
        #FIXME this repo doesn't exist yet! (https://www.mediawiki.org/wiki/Git/New_repositories/Requests)
        origin    => 'git clone https://addshore@gerrit.wikimedia.org/r/analytics/wmde/toolkit-analyzer-build',
        owner     => 'wmde-analytics',
        group     => 'wmde-analytics',
        require => User['wmde-analytics'],
    }

    cron { 'minutely':
        ensure  => present,
        command => '/home/wmde-analytics/git/scripts/minutely.sh > /home/wmde-analytics/log/minutely.log 2>&1',
        user    => 'wmde-analytics',
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
