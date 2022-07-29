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

    ensure_packages([
        'php',
        'php-cli',
        'php-xml'
    ])

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

    file { "${dir}/src/config":
        ensure  => 'file',
        owner   => 'root',
        group   => $user,
        mode    => '0440',
        content => template('statistics/wmde/config.erb'),
        require => File["${dir}/src"],
    }

    systemd::timer::job { 'wmde-analytics-minutely':
        ensure              => present,
        description         => 'Minutely jobs for wmde analytics infrastructure',
        user                => $user,
        command             => "${scripts_dir}/cron/minutely.sh ${scripts_dir}",
        require             => Git::Clone['wmde/scripts'],
        interval            => {'start' => 'OnCalendar', 'interval' => '*-*-* *:*:0'},
        max_runtime_seconds => 55,  # kill if still running after 55s
    }

    # Note: some of the scripts run by this cron need access to secrets!
    # Docs can be seen at https://github.com/wikimedia/analytics-wmde-scripts/blob/master/README.md
    systemd::timer::job { 'wmde-analytics-daily-early':
        ensure              => present,
        description         => 'Daily jobs for wmde analytics infrastructure',
        user                => $user,
        command             => "/usr/bin/time ${scripts_dir}/cron/daily.03.sh ${scripts_dir}",
        require             => [
            Git::Clone['wmde/scripts'],
            File["${dir}/src/config"],
            Mariadb::Config::Client['research-wmde'],
        ],
        interval            => {'start' => 'OnCalendar', 'interval' => '*-*-* 3:0:0'},
        max_runtime_seconds => 72000,  # kill if still running after 20h
    }

    systemd::timer::job { 'wmde-analytics-daily-noon':
        ensure              => present,
        description         => 'Daily jobs for wmde analytics infrastructure',
        user                => $user,
        command             => "/usr/bin/time ${scripts_dir}/cron/daily.12.sh ${scripts_dir}",
        require             => [
            Git::Clone['wmde/scripts'],
            File["${dir}/src/config"],
            Mariadb::Config::Client['research-wmde'],
        ],
        interval            => {'start' => 'OnCalendar', 'interval' => '*-*-* 12:0:0'},
        max_runtime_seconds => 72000,  # kill if still running after 20h
    }

    systemd::timer::job { 'wmde-analytics-weekly':
        ensure              => present,
        description         => 'Weekly jobs for wmde analytics infrastructure',
        user                => $user,
        command             => "/usr/bin/time ${scripts_dir}/cron/weekly.sh ${scripts_dir}",
        require             => [
            Git::Clone['wmde/scripts'],
            File["${dir}/src/config"],
        ],
        interval            => {'start' => 'OnCalendar', 'interval' => 'Sunday 0:0:0'},
        max_runtime_seconds => 518400,  # kill if still running after 6d
    }

    # Disabled until T278665 is solved
    systemd::timer::job { 'wmde-toolkit-analyzer-build':
        ensure      => absent,
        description => 'Daily jobs for rebuilding wmde analyzor toolkit',
        user        => $user,
        command     => "/usr/bin/java -Dhttp.proxyHost=\"http://webproxy.${::site}.wmnet\" -Dhttp.proxyPort=8080 -Xmx2g -jar ${dir}/src/toolkit-analyzer-build/toolkit-analyzer.jar --processors Metric --store ${dir}/data --latest",
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 12:0:0'},
    }

}
