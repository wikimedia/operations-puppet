# == Class role::analytics::refinery
# Includes configuration and resources needed for deploying
# and using the analytics/refinery repository.
#
class role::analytics::refinery {
    # Require analytics users so we hdfs can write log files as stats user.
    require role::analytics::users

    # Many Kraken python scripts use docopt for CLI parsing.
    if !defined(Package['python-docopt']) {
        package { 'python-docopt':
            ensure => 'installed',
        }
    }
    # refinery python module uses dateutil
    if !defined(Package['python-dateutil']) {
        package { 'python-dateutil':
            ensure => 'installed',
        }
    }

    # analytics/refinery will deployed to this node.
    deployment::target { 'analytics-refinery': }

    # analytics/refinery repository is deployed via git-deploy at this path.
    # You must deploy this yourself; puppet will not do it for you.
    $path = '/srv/deployment/analytics/refinery'

    # Put refinery python module in user PYTHONPATH
    file { '/etc/profile.d/refinery.sh':
        content => "export PYTHONPATH=\${PYTHONPATH}:${path}/python"
    }

    # Create directory in /var/log for general purpose Refinery job logging.
    $log_dir = '/var/log/refinery'
    file { $log_dir:
        ensure => 'directory',
        owner  => 'root',
        group  => 'stats',
        # setgid bit here to make kraken log files writeable
        # by users in the stats group.
        mode   => '2775',
    }
}

# Installs cron job to drop old hive partitions
# and delete old data from HDFS.
class role::analytics::refinery::data::drop {
    require role::analytics::refinery

    $log_file     = "${role::analytics::refinery::log_dir}/drop-webrequest-partitions.log"

    # keep this many days of data
    $retention_days = 31
    cron { 'refinery-drop-webrequest-partitions':
        command => "export PYTHONPATH=\${PYTHONPATH}:${role::analytics::refinery::path}/python && ${role::analytics::refinery::path}/bin/refinery-drop-webrequest-partitions -d ${retention_days} -D wmf >> ${log_file} 2>&1",
        user    => 'hdfs',
        hour    => '*/4',
    }
}
