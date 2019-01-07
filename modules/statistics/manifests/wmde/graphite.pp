# Licence AGPL version 3 or later
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
#
# == Parameters
#   dir           - string. Directory to use.
#   user          - string. User to run scripts as.
#   statsd_host   - string. Host to use for statsd data.
#   graphite_host - string. Host to use for graphite data.
#   wmde_secrets
class statistics::wmde::graphite(
    $dir,
    $user,
    $statsd_host,
    $graphite_host,
    $wmde_secrets,
) {

    $scripts_dir  = "${dir}/src/scripts"
    # Path in which all crons will log to.
    $log_dir = "${dir}/log"

    require_package('openjdk-8-jdk')
    require_package(
        'php',
        'php-cli',
        'php-xml'
    )

    include ::passwords::mysql::research
    # This file will render at
    # /etc/mysql/conf.d/research-wmde-client.cnf.
    mariadb::config::client { 'research-wmde':
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

    logrotate::conf { 'statistics-wmde-graphite':
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
            Mariadb::Config::Client['research-wmde'],
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
        command => "time java -Dhttp.proxyHost=\"http://webproxy.${::site}.wmnet\" -Dhttp.proxyPort=8080 -Xmx2g -jar ${dir}/src/toolkit-analyzer-build/toolkit-analyzer.jar --processors Metric --store ${dir}/data --latest >> ${log_dir}/toolkit-analyzer.log 2>&1",
        hour    => '12',
        minute  => '0',
    }

}
