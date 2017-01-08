# Licence AGPL version 3 or later
#
# Class for running WMDE releated analytics scripts.
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

    $statistics_working_path = $::statistics::working_path
    class { 'statistics::wmde::user':
        homedir => "${statistics_working_path}/analytics-wmde",
    }
    $user = $statistics::wmde::user::username
    $dir = $statistics::wmde::user::homedir
    $data_dir  = "${dir}/data"
    $scripts_dir  = "${dir}/src/scripts"

    $statsd_host = hiera('statsd')
    # TODO graphite hostname should be in hiera
    $graphite_host = 'graphite.eqiad.wmnet'

    # Path in which all crons will log to.
    $log_dir = "${dir}/log"

    $wmde_secrets = hiera('wmde_secrets')

    require_package(
        'openjdk-7-jdk',
        'php5',
        'php5-cli',
    )

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
        $log_dir,
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
        branch    => 'production',
        directory => $scripts_dir,
        origin    => 'https://gerrit.wikimedia.org/r/analytics/wmde/scripts',
        owner     => $user,
        group     => $user,
        require   => File["${dir}/src"],
    }

    git::clone { 'wmde/toolkit-analyzer-build':
        ensure    => 'latest',
        branch    => 'production',
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

    Cron {
        user => $user,
    }

    cron { 'minutely':
        command => "${scripts_dir}/cron/minutely.sh ${scripts_dir} >> ${log_dir}/minutely.log 2>&1",
        hour    => '*',
        minute  => '*',
        require => Git::Clone['wmde/scripts'],
    }

    # Note: some of the scripts run by this cron need access to secrets!
    # Docs can be seen at https://github.com/wikimedia/analytics-wmde-scripts/blob/master/README.md
    cron { 'daily.03':
        command => "time ${scripts_dir}/cron/daily.03.sh ${scripts_dir} >> ${log_dir}/daily.03.log 2>&1",
        hour    => '3',
        minute  => '0',
        require => [
            Git::Clone['wmde/scripts'],
            File["${dir}/src/config"],
            Mysql::Config::Client['research-wmde'],
        ],
    }

    cron { 'daily.12':
        command => "time ${scripts_dir}/cron/daily.12.sh ${scripts_dir} >> ${log_dir}/daily.12.log 2>&1",
        hour    => '12',
        minute  => '0',
        require => [
            Git::Clone['wmde/scripts'],
            File["${dir}/src/config"],
        ],
    }

    cron { 'weekly':
        command => "time ${scripts_dir}/cron/weekly.sh ${scripts_dir} >> ${log_dir}/weekly.log 2>&1",
        weekday => '7',
        hour    => '01',
        minute  => '0',
        require => [
            Git::Clone['wmde/scripts'],
            File["${dir}/src/config"],
        ],
    }

    cron { 'wmde/toolkit-analyzer-build':
        command => "time java -Xmx2g -jar ${dir}/src/toolkit-analyzer-build/toolkit-analyzer.jar --processors Metric --store ${dir}/data --latest >> ${log_dir}/toolkit-analyzer.log 2>&1",
        hour    => '12',
        minute  => '0',
    }

}
