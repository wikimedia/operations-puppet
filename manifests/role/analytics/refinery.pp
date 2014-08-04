# == Class role::analytics::refinery
# Includes configuration and resources needed for deploying
# and using the analytics/refinery repository.
#
class role::analytics::refinery {
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
        # TODO: Change this to analytics-admins group after
        # https://gerrit.wikimedia.org/r/#/c/150560 is merged.
        group  => 'stats',
        # setgid bit here to make kraken log files writeable
        # by users in the stats group.
        mode   => '2775',
    }
}

# == Class role::analytics::refinery::camus
# Submits Camus MapReduce jobs to import data from Kafka.
#
class role::analytics::refinery::camus {
    require role::analytics::refinery

    $camus_webrequest_properties = "${::role::analytics::refinery::path}/camus/camus.webrequest.properties"
    $camus_webrequest_log_file   = "${::role::analytics::refinery::log_dir}/camus-webrequest.log"
    cron { 'refinery-camus-webrequest-import':
        command => "${::role::analytics::refinery::path}/bin/camus --job-name refinery-camus-webrequest-import ${camus_webrequest_properties} >> ${camus_webrequest_log_file} 2>&1",
        user    => 'hdfs',  # we might want to use a different user for this, not sure.
        minute  => '*/10',
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
