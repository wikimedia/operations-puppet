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
class statistics::wmde {
    Class['::statistics'] -> Class['::statistics::wmde']

    $user = 'analytics-wmde'
    $dir  = "${::statistics::working_path}/analytics-wmde"
    $data_dir  = "${dir}/data"
    $scripts_dir  = "${dir}/src/scripts"

    # Path in which all crons will log to.
    $log_dir = "${dir}/log"

    $wmde_secrets = hiera('wmde_secrets')

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
        managehome => false,
        home       => $dir,
        system     => true,
        require    => Group[$user],
    }

    include passwords::mysql::research
    # This file will render at
    # /etc/mysql/conf.d/research-wmde-client.cnf.
    mysql::config::client { 'research-wmde':
        user    => $::passwords::mysql::research::user,
        pass    => $::passwords::mysql::research::pass,
        group   => $user,
        mode    => '0440',
        require => User[$user],
    }

    $directories = [
        $dir,
        "${dir}/src",
        "${dir}/data",
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
        ensure    => 'ebb14fdaa093ee44888f122aa23407f67b56cdef ',
        directory => "${dir}/src/scripts",
        origin    => 'https://gerrit.wikimedia.org/r/analytics/wmde/scripts',
        owner     => $user,
        group     => $user,
        require   => File["${dir}/src"],
    }

    git::clone { 'wmde/toolkit-analyzer-build':
        ensure    => '5030ff6f98bf1ef463e726883ae03a67819815e8',
        directory => "${dir}/src/toolkit-analyzer-build",
        origin    => 'https://gerrit.wikimedia.org/r/analytics/wmde/toolkit-analyzer-build',
        owner     => $user,
        group     => $user,
        require   => File["${dir}/src"],
    }

    logrotate::conf { 'statistics-wmde':
        ensure  => present,
        content => template('statistics/wmde/logrotate.erb'),
        require => File[$log_dir],
    }

    file { "${dir}/src/config":
        ensure  => 'file',
        owner   => 'root',
        group   => $user,
        mode    => '0440',
        content => template('statistics/wmde/config.erb'),
        require => File["${dir}/src"],
    }

    file { "${dir}/daily.sh":
        ensure  => 'file',
        owner   => $user,
        group   => $user,
        mode    => '0754',
        content => template('statistics/wmde/daily.erb'),
        require => Git::Clone['wmde/scripts'],
    }

    file { "${dir}/minutely.sh":
        ensure  => 'file',
        owner   => $user,
        group   => $user,
        mode    => '0754',
        content => template('statistics/wmde/minutely.erb'),
        require => Git::Clone['wmde/scripts'],
    }

    Cron {
        user => $user,
    }

    cron { 'minutely':
        command => "${dir}/minutely.sh >> ${log_dir}/minutely.log 2>&1",
        hour    => '*',
        minute  => '*',
        require => File["${dir}/minutely.sh"],
    }

    # Note: some of the scripts run by this cron need access to secrets!
    # Docs can be seen at https://github.com/wikimedia/analytics-wmde-scripts/blob/master/README.md
    cron { 'daily':
        command => "${dir}/daily.sh >> ${log_dir}/daily.log 2>&1",
        hour    => '3',
        minute  => '0',
        require => [
            File["${dir}/daily.sh"],
            File["${dir}/src/config"],
            mysql::config::client['research-wmde'],
        ],
    }

    # Logrotate is at 6:25, + time for rsync (hourly?), 12 gives us roughly 6 hours
    cron { 'graphite/api/logScanner':
        command => "${dir}/src/scripts/graphite/api/logScanner.sh >> ${log_dir}/graphite_api_logScanner.log 2>&1",
        hour    => '12',
        minute  => '0',
    }

    cron { 'wmde/toolkit-analyzer-build':
        command => "java -Xmx2g -jar ${dir}/src/toolkit-analyzer-build/toolkit-analyzer.jar --processors Metric --store ${dir}/data --latest >> ${log_dir}/toolkit-analyzer.log 2>&1",
        hour    => '12',
        minute  => '0',
    }

}
