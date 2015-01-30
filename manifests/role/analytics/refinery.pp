# == Class role::analytics::refinery
# Includes configuration and resources needed for deploying
# and using the analytics/refinery repository.
#
class role::analytics::refinery {
    # Make this class depend on hadoop::client.  Refinery
    # is intended to work with Hadoop, and many of the
    # role classes here use the hdfs user, which is created
    # by the CDH packages.
    Class['role::analytics::hadoop::client'] -> Class['role::analytics::refinery']

    # Some refinery python scripts use docopt for CLI parsing.
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
    package { 'analytics/refinery':
        provider => 'trebuchet',
    }

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
        owner  => 'hdfs',
        group  => 'analytics-admins',
        # setgid bit here to make refinery log files writeable
        # by users in the analytics-admins group.
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

# == Class role::analytics::refinery::data::drop
# Installs cron job to drop old hive partitions
# and delete old data from HDFS.
#
class role::analytics::refinery::data::drop {
    require role::analytics::refinery

    $log_file     = "${role::analytics::refinery::log_dir}/drop-webrequest-partitions.log"

    # keep this many days of data
    $retention_days = 40
    cron { 'refinery-drop-webrequest-partitions':
        command => "export PYTHONPATH=\${PYTHONPATH}:${role::analytics::refinery::path}/python && ${role::analytics::refinery::path}/bin/refinery-drop-webrequest-partitions -d ${retention_days} -D wmf_raw -l /wmf/data/raw/webrequest >> ${log_file} 2>&1",
        user    => 'hdfs',
        minute  => '15',
        hour    => '*/4',
    }
}

# == Class role::analytics::refinery::data::check::icinga
# Configures passive/freshness icinga checks or data imports
# in HDFS.
#
# For webrequest imports, the Oozie job that is responsible
# for adding Hive partitions and checking data integrity
# is responsible for triggering these passive checks.
#
# NOTE:  These are disasbled due to nsca not working
# properly between versions provided in Precise and Trusty.
# we may reenable these if the icinga server gets upgraded
# to Trusty.
# See: https://phabricator.wikimedia.org/T76414
#      https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=670373
#
class role::analytics::refinery::data::check::icinga {
    # We are monitoring hourly datasets.
    # Give Oozie a little time to finish running
    # the monitor_done_flag workflow for each hour.
    # 5400 seconds == 1.5 hours.
    $freshness_threshold = 5400

    # 1 == warning, 2 == critical.
    # Use warning for now while we make sure this works.
    $alert_return_code   = 1

    # Monitor that each webrequest source is succesfully imported.
    # This is a passive check that is triggered by the Oozie
    # webrequest add partition jobs.
    monitoring::service { 'hive_partition_webrequest-bits':
        ensure          => 'absent',
        description     => 'hive_partition_webrequest-bits',
        check_command   => "analytics_cluster_data_import-FAIL!wmf_raw.webrequest bits!${alert_return_code}",
        passive         => 'true',
        freshness       => $freshness_threshold,
        retries         => 1,
    }
    monitoring::service { 'hive_partition_webrequest-mobile':
        ensure          => 'absent',
        description     => 'hive_partition_webrequest-mobile',
        check_command   => "analytics_cluster_data_import-FAIL!wmf_raw.webrequest mobile!${alert_return_code}",
        passive         => 'true',
        freshness       => $freshness_threshold,
        retries         => 1,
    }
    monitoring::service { 'hive_partition_webrequest-text':
        ensure          => 'absent',
        description     => 'hive_partition_webrequest-text',
        check_command   => "analytics_cluster_data_import-FAIL!wmf_raw.webrequest text!${alert_return_code}",
        passive         => 'true',
        freshness       => $freshness_threshold,
        retries         => 1,
    }
    monitoring::service { 'hive_partition_webrequest-upload':
        ensure          => 'absent',
        description     => 'hive_partition_webrequest-upload',
        check_command   => "analytics_cluster_data_import-FAIL!wmf_raw.webrequest upload!${alert_return_code}",
        passive         => 'true',
        freshness       => $freshness_threshold,
        retries         => 1,
    }
}

# == Class role::analytics::refinery::data::check::email
# Configures cron jobs that send email about the faultyness of webrequest data
#
# These checks walk HDFS through the plain file system.
#
class role::analytics::refinery::data::check::email {
    require role::analytics::refinery

    # This should not be hardcoded.  Instead, one should be able to use
    # $::cdh::hadoop::mount::mount_point to reference the user supplied
    # parameter when the cdh::hadoop::mount class is evaluated.
    # I am not sure why this is not working.
    $hdfs_mount_point = '/mnt/hdfs'

    # Since the 'stats' user is not in ldap, it is unnecessarily hard
    # to grant it access to the private data in hdfs. As discussed in
    #   https://gerrit.wikimedia.org/r/#/c/186254
    # the cron runs as hdfs instead.
    cron { 'refinery data check hdfs_mount':
        command     => "${::role::analytics::refinery::path}/bin/refinery-dump-status-webrequest-partitions --hdfs-mount ${hdfs_mount_point} --datasets webrequest,raw_webrequest --quiet",
        environment => 'MAILTO=otto@wikimedia.org,jgage@wikimedia.org',
        user        => 'hdfs',
        hour        => 10,
        minute      => 0,
    }
}
