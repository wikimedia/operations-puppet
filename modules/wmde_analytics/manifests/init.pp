# Licence AGPL version 3 or later
#
# Module for running WMDE releated analytics scripts.
#
# @author Addshore
#
# These scripts get metrics from a variety of places including:
#  - Databases
#  - Log files
#  - Hive
#  - Dumps
#
# And send the data to statsd or graphite directly
class wmde_analytics(
    $user = 'wmde-analytics',
    $log_dir = '/home/wmde-analytics/log/'
) {

    require_package(
        #TODO JAVA runtime!?
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
        origin    => 'git clone https://gerrit.wikimedia.org/r/analytics/wmde/scripts',
        owner     => $user,
        group     => $user,
        require   => User[$user],
    }

    git::clone { 'wmde/toolkit-analyzer-build':
        ensure    => 'latest',
        directory => "/home/${$user}/git/toolkit-analyzer-build",
        origin    => 'git clone https://gerrit.wikimedia.org/r/analytics/wmde/toolkit-analyzer-build',
        owner     => $user,
        group     => $user,
        require   => User[$user],
    }

    file { $log_dir:
        ensure => 'directory',
        owner  => $user,
        group  => $user,
        mode   => '0644',
    }

    logrotate::conf { 'wmde_analytics':
        ensure  => present,
        content => template('wmde_analytics/logrotate.erb'),
        require => File[$log_dir],
    }

    #TODO is there some way of simplifying the below massive list of crons?

    # Minutely cron
    cron { 'minutely':
        ensure  => present,
        command => "/home/${$user}/git/scripts/minutely.sh >> /home/${$user}/log/minutely.log 2>&1",
        user    => $user,
        hour    => '*',
        minute  => '*',
        require => Git::Clone['wmde/scripts'],
    }

    # Daily cron
    cron { 'daily_datamodel':
        ensure  => present,
        command => "/home/${$user}/git/scripts/daily_datamodel.sh >> /home/${$user}/log/daily_datamodel.log 2>&1",
        user    => $user,
        hour    => '3',
        minute  => '0',
        require => Git::Clone['wmde/scripts'],
    }
    cron { 'graphite/entityUsage':
        ensure  => present,
        command => "/home/${$user}/git/scripts/graphite/entityUsage.sh >> /home/${$user}/log/graphite/entityUsage.log 2>&1",
        user    => $user,
        hour    => '4',
        minute  => '0',
        require => Git::Clone['wmde/scripts'],
    }
    cron { 'daily_social':
        ensure  => present,
        command => "/home/${$user}/git/scripts/daily_social.sh >> /home/${$user}/log/daily_social.log 2>&1",
        user    => $user,
        hour    => '5',
        minute  => '0',
        require => Git::Clone['wmde/scripts'],
    }
    cron { 'daily_misc':
        ensure  => present,
        command => "/home/${$user}/git/scripts/daily_misc.sh >> /home/${$user}/log/daily_misc.log 2>&1",
        user    => $user,
        hour    => '5',
        minute  => '30',
        require => Git::Clone['wmde/scripts'],
    }
    cron { 'daily_site_stats':
        ensure  => present,
        command => "/home/${$user}/git/scripts/daily_site_stats.sh >> /home/${$user}/log/daily_site_stats.log 2>&1",
        user    => $user,
        hour    => '6',
        minute  => '0',
        require => Git::Clone['wmde/scripts'],
    }

    # Logrotate is at 6:25, + time for rsync (hourly?), 12 gives us roughly 6 hours
    cron { 'graphite/api/logScanner':
        ensure  => present,
        command => "/home/${$user}/git/scripts/graphite/api/logScanner.sh >> /home/${$user}/log/graphite_api_logScanner.log 2>&1",
        user    => $user,
        hour    => '12',
        minute  => '0',
        require => Git::Clone['wmde/scripts'],
    }

    # Weekly cron
    cron { 'wmde/toolkit-analyzer-build':
        ensure  => present,
        command => "java -Xmx2g -jar /home/${$user}/git/scripts/toolkit-analyzer-build/toolkit-analyzer.jar --processors Metric --store /home/${$user}/data --latest >> /home/${$user}/log/toolkit-analyzer.log 2>&1",
        user    => $user,
        hour    => '12',
        minute  => '0',
        require => Git::Clone['wmde/scripts'],
    }

}
