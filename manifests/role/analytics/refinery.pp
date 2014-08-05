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
        group  => 'analytics-admins',
        # setgid bit here to make refinery log files writeable
        # by users in the analytics-admins group.
        mode   => '2775',
    }

    # If hdfs user exists, then add it to the analytics-admins group.
    # I don't want to use puppet types or the admin module to manage
    # the hdfs user, since it is installed by the CDH packages.
    # TODO: Move this to the admin module if/when it supports
    # adding system users to groups.
    exec { 'hdfs_user_in_stats_group':
        command => 'usermod hdfs -a -G analytics-admins',
        # Only run this command if the hdfs user exists
        # and it is not already in the stats group
        # This command returns true if hdfs user does not exist,
        # or if hdfs user does exist and is in the stats group.
        unless  => 'getent passwd hdfs > /dev/null; if [ $? != 0 ]; then true; else groups hdfs | grep -q analytics-admins; fi',
        path    => '/usr/sbin:/usr/bin:/bin',
        require => Group['analytics-admins'],
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
