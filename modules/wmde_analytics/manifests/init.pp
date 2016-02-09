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
    $dir = '/srv/analytics-wmde/',
    $log_dir = '/var/log/analytics-wmde/'
) {

    require_package(
        'openjdk-7-jdk',
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
        require    => Group[$user],
    }

    include passwords::mysql::research
    # This file will render at
    # /etc/mysql/conf.d/wmde-analytics-client.cnf.
    mysql::config::client { 'wmde_analytics':
        user    => $::passwords::mysql::research::user,
        pass    => $::passwords::mysql::research::pass,
        group   => $user,
        mode    => '0440',
        require => User[$user],
    }

    $directories = [
        $dir,
        "${$dir}/src",
        "${$dir}/data",
        $log_dir
    ]

    file { $directories:
        ensure  => 'directory',
        owner   => $user,
        group   => $user,
        mode    => '0644',
        require => User[$user],
    }

    git::clone { 'wmde/scripts':
        ensure    => 'latest',
        directory => "${$dir}/src/scripts",
        origin    => 'git clone https://gerrit.wikimedia.org/r/analytics/wmde/scripts',
        owner     => $user,
        group     => $user,
        require   => File["${$dir}/src"],
    }

    git::clone { 'wmde/toolkit-analyzer-build':
        ensure    => 'latest',
        directory => "${$dir}/src/toolkit-analyzer-build",
        origin    => 'git clone https://gerrit.wikimedia.org/r/analytics/wmde/toolkit-analyzer-build',
        owner     => $user,
        group     => $user,
        require   => File["${$dir}/src"],
    }

    logrotate::conf { 'wmde_analytics':
        ensure  => present,
        content => template('wmde_analytics/logrotate.erb'),
        require => File[$log_dir],
    }

    file { "${$dir}/src/config":
        ensure  => 'file',
        owner   => 'root',
        group   => $user,
        mode    => '0440',
        content => template('wmde_analytics/config.erb'),
        require => User["${$dir}/src"],
    }

    file { "${$dir}/daily.sh":
        ensure  => 'file',
        owner   => $user,
        group   => $user,
        mode    => '0644',
        content => template('wmde_analytics/daily.erb'),
        require => Git::Clone['wmde/scripts'],
    }

    file { "${$dir}/minutely.sh":
        ensure  => 'file',
        owner   => $user,
        group   => $user,
        mode    => '0644',
        content => template('wmde_analytics/minutely.erb'),
        require => Git::Clone['wmde/scripts'],
    }

    Cron {
        user => $user,
    }

    cron { 'minutely':
        command => "${$dir}/minutely.sh >> ${$log_dir}/minutely.log 2>&1",
        hour    => '*',
        minute  => '*',
        require => File["${$dir}/minutely.sh"],
    }

    # Note: some of the scripts run by this cron need access to secrets!
    # Docs can be seen at https://github.com/wikimedia/analytics-wmde-scripts/blob/master/README.md
    cron { 'daily':
        command => "${$dir}/daily.sh >> ${$log_dir}/daily.log 2>&1",
        hour    => '3',
        minute  => '0',
        require => [
            File["${$dir}/daily.sh"],
            File["${$dir}/src/config"],
            mysql::config::client['wmde_analytics'],
        ],
    }

    # Logrotate is at 6:25, + time for rsync (hourly?), 12 gives us roughly 6 hours
    cron { 'graphite/api/logScanner':
        command => "${$dir}/src/scripts/graphite/api/logScanner.sh >> ${$log_dir}/graphite_api_logScanner.log 2>&1",
        hour    => '12',
        minute  => '0',
    }

    cron { 'wmde/toolkit-analyzer-build':
        command => "java -Xmx2g -jar ${$dir}/src/toolkit-analyzer-build/toolkit-analyzer.jar --processors Metric --store ${$dir}/data --latest >> ${$log_dir}/toolkit-analyzer.log 2>&1",
        hour    => '12',
        minute  => '0',
    }

}
