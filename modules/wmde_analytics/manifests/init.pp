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
    $user = 'analytics-wmde',
    $src_dir = '/srv/analytics-wmde/src/',
    $data_dir = '/srv/analytics-wmde/data/',
    $log_dir = '/var/log/analytics-wmde/'
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

    file { $src_dir:
        ensure => 'directory',
        owner  => $user,
        group  => $user,
        mode   => '0644',
    }

    file { $data_dir:
        ensure => 'directory',
        owner  => $user,
        group  => $user,
        mode   => '0644',
    }

    file { $log_dir:
        ensure => 'directory',
        owner  => $user,
        group  => $user,
        mode   => '0644',
    }

    git::clone { 'wmde/scripts':
        ensure    => 'latest',
        directory => "${$src_dir}/scripts",
        origin    => 'git clone https://gerrit.wikimedia.org/r/analytics/wmde/scripts',
        owner     => $user,
        group     => $user,
        require   => User[$user],
    }

    git::clone { 'wmde/toolkit-analyzer-build':
        ensure    => 'latest',
        directory => "${$src_dir}/toolkit-analyzer-build",
        origin    => 'git clone https://gerrit.wikimedia.org/r/analytics/wmde/toolkit-analyzer-build',
        owner     => $user,
        group     => $user,
        require   => User[$user],
    }

    logrotate::conf { 'wmde_analytics':
        ensure  => present,
        content => template('wmde_analytics/logrotate.erb'),
        require => File[$log_dir],
    }

    Cron {
        user => $user,
    }

    # Minutely cron
    cron { 'minutely':
        command => "${$src_dir}/scripts/minutely.sh >> ${$log_dir}/minutely.log 2>&1",
        hour    => '*',
        minute  => '*',
        require => Git::Clone['wmde/scripts'],
    }

    # Daily cron
    cron { 'daily_datamodel':
        command => "${$src_dir}/scripts/daily_datamodel.sh >> ${$log_dir}/daily_datamodel.log 2>&1",
        hour    => '3',
        minute  => '0',
        require => Git::Clone['wmde/scripts'],
    }
    cron { 'graphite/entityUsage':
        command => "${$src_dir}/scripts/graphite/entityUsage.sh >> ${$log_dir}/graphite/entityUsage.log 2>&1",
        hour    => '4',
        minute  => '0',
        require => Git::Clone['wmde/scripts'],
    }
    # FIXME some of the scripts run by this cron need access to secrets!
    # Docs can be seen at https://github.com/wikimedia/analytics-wmde-scripts/blob/master/README.md
    cron { 'daily_social':
        command => "${$src_dir}/scripts/daily_social.sh >> ${$log_dir}/daily_social.log 2>&1",
        hour    => '5',
        minute  => '0',
        require => Git::Clone['wmde/scripts'],
    }
    cron { 'daily_misc':
        command => "${$src_dir}/scripts/daily_misc.sh >> ${$log_dir}/daily_misc.log 2>&1",
        hour    => '5',
        minute  => '30',
        require => Git::Clone['wmde/scripts'],
    }
    cron { 'daily_site_stats':
        command => "${$src_dir}/scripts/daily_site_stats.sh >> ${$log_dir}/daily_site_stats.log 2>&1",
        hour    => '6',
        minute  => '0',
        require => Git::Clone['wmde/scripts'],
    }

    # Logrotate is at 6:25, + time for rsync (hourly?), 12 gives us roughly 6 hours
    cron { 'graphite/api/logScanner':
        command => "${$src_dir}/scripts/graphite/api/logScanner.sh >> ${$log_dir}/graphite_api_logScanner.log 2>&1",
        hour    => '12',
        minute  => '0',
        require => Git::Clone['wmde/scripts'],
    }

    # Weekly cron
    # FIXME daily_datamodel.sh runs scripts/graphite/wikidata-analysis/metrics.php which uses the output of this script
    # but right now the location of the output files it looks for is hard coded and should be fixed / passed as a param.
    cron { 'wmde/toolkit-analyzer-build':
        command => "java -Xmx2g -jar ${$src_dir}/toolkit-analyzer-build/toolkit-analyzer.jar --processors Metric --store ${$data_dir} --latest >> ${$log_dir}/toolkit-analyzer.log 2>&1",
        hour    => '12',
        minute  => '0',
        require => Git::Clone['wmde/toolkit-analyzer-build'],
    }

}
