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
# Uses camus::job to set up cron jobs to
# import data from Kafka into Hadoop.
#
class role::analytics::refinery::camus {
    require role::analytics::refinery
    include role::analytics::kafka::config

    # Make all uses of camus::job set kafka_brokers to this
    Camus::Job {
        kafka_brokers => suffix($role::analytics::kafka::config::brokers_array, ':9092')
    }

    # Import webrequest_* topics into /wmf/data/raw/webrequest
    # every 10 minutes, check runs and flag fully imported hours.
    camus::job { 'webrequest':
        check  => true,
        minute => '*/10',
    }

    # Import eventlogging_* topics into /wmf/data/raw/eventlogging
    # once every hour.
    camus::job { 'eventlogging':
        minute => '5',
    }

    # Import mediawiki_* topics into /wmf/data/raw/mediawiki
    # once every hour.  This data is expected to be Avro binary.
    camus::job { 'mediawiki':
        check  => true,
        minute  => '15',
        # refinery-camus contains some custom decoder classes which
        # are needed to import Avro binary data.
        libjars => "${role::analytics::refinery::path}/artifacts/refinery-camus.jar"
    }
}

# == Class role::analytics::refinery::data::drop
# Installs cron job to drop old hive partitions
# and delete old data from HDFS.
#
class role::analytics::refinery::data::drop {
    require role::analytics::refinery

    $webrequest_log_file     = "${role::analytics::refinery::log_dir}/drop-webrequest-partitions.log"
    $eventlogging_log_file   = "${role::analytics::refinery::log_dir}/drop-eventlogging-partitions.log"

    # keep this many days of raw webrequest data
    $raw_retention_days = 31
    cron { 'refinery-drop-webrequest-raw-partitions':
        command => "export PYTHONPATH=\${PYTHONPATH}:${role::analytics::refinery::path}/python && ${role::analytics::refinery::path}/bin/refinery-drop-webrequest-partitions -d ${raw_retention_days} -D wmf_raw -l /wmf/data/raw/webrequest -w raw >> ${webrequest_log_file} 2>&1",
        user    => 'hdfs',
        minute  => '15',
        hour    => '*/4',
    }

    # keep this many days of refined webrequest data
    $refined_retention_days = 62
    cron { 'refinery-drop-webrequest-refined-partitions':
        command => "export PYTHONPATH=\${PYTHONPATH}:${role::analytics::refinery::path}/python && ${role::analytics::refinery::path}/bin/refinery-drop-webrequest-partitions -d ${refined_retention_days} -D wmf -l /wmf/data/wmf/webrequest -w refined >> ${webrequest_log_file} 2>&1",
        user    => 'hdfs',
        minute  => '45',
        hour    => '*/4',
    }

    # keep this many days of eventlogging data
    $eventlogging_retention_days = 90
    cron {'refinery-drop-eventlogging-partitions':
        command => "export PYTHONPATH=\${PYTHONPATH}:${role::analytics::refinery::path}/python && ${role::analytics::refinery::path}/bin/refinery-drop-eventlogging-partitions -d ${eventlogging_retention_days} -l /wmf/data/raw/eventlogging >> ${eventlogging_log_file} 2>&1",
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
        ensure        => 'absent',
        description   => 'hive_partition_webrequest-bits',
        check_command => "analytics_cluster_data_import-FAIL!wmf_raw.webrequest bits!${alert_return_code}",
        passive       => true,
        freshness     => $freshness_threshold,
        retries       => 1,
    }
    monitoring::service { 'hive_partition_webrequest-mobile':
        ensure        => 'absent',
        description   => 'hive_partition_webrequest-mobile',
        check_command => "analytics_cluster_data_import-FAIL!wmf_raw.webrequest mobile!${alert_return_code}",
        passive       => true,
        freshness     => $freshness_threshold,
        retries       => 1,
    }
    monitoring::service { 'hive_partition_webrequest-text':
        ensure        => 'absent',
        description   => 'hive_partition_webrequest-text',
        check_command => "analytics_cluster_data_import-FAIL!wmf_raw.webrequest text!${alert_return_code}",
        passive       => true,
        freshness     => $freshness_threshold,
        retries       => 1,
    }
    monitoring::service { 'hive_partition_webrequest-upload':
        ensure        => 'absent',
        description   => 'hive_partition_webrequest-upload',
        check_command => "analytics_cluster_data_import-FAIL!wmf_raw.webrequest upload!${alert_return_code}",
        passive       => true,
        freshness     => $freshness_threshold,
        retries       => 1,
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

    $mail_to = 'analytics-alerts@wikimedia.org'

    # Since the 'stats' user is not in ldap, it is unnecessarily hard
    # to grant it access to the private data in hdfs. As discussed in
    #   https://gerrit.wikimedia.org/r/#/c/186254
    # the cron runs as hdfs instead.
    cron { 'refinery data check hdfs_mount':
        command     => "${::role::analytics::refinery::path}/bin/refinery-dump-status-webrequest-partitions --hdfs-mount ${hdfs_mount_point} --datasets webrequest,raw_webrequest --quiet --percent-lost",
        environment => "MAILTO=${$mail_to}",
        user        => 'hdfs',
        hour        => 10,
        minute      => 0,
    }

    cron { 'refinery data check pagecounts':
        command     => "${::role::analytics::refinery::path}/bin/refinery-dump-status-webrequest-partitions --hdfs-mount ${hdfs_mount_point} --datasets pagecounts_all_sites,pagecounts_raw --quiet",
        environment => "MAILTO=${$mail_to}",
        user        => 'hdfs', # See comment in above cron
        hour        => 10,
        minute      => 5,
    }

    cron { 'refinery data check pageviews':
        command     => "${::role::analytics::refinery::path}/bin/refinery-dump-status-webrequest-partitions --hdfs-mount ${hdfs_mount_point} --datasets pageview,projectview --quiet",
        environment => "MAILTO=${$mail_to}",
        user        => 'hdfs', # See comment in first cron above
        hour        => 10,
        minute      => 10,
    }
}

# == Class role::analytics::refinery::source
# Clones analytics/refinery/source repo and keeps it up-to-date
#
class role::analytics::refinery::source {
    require statistics

    $path = "${::statistics::working_path}/refinery-source"

    $user = $::statistics::user::username
    $group = $user

    file { $path:
        ensure => 'directory',
        owner  => $user,
        group  => $group,
        mode   => '0755',
    }

    git::clone { 'refinery_source':
        ensure    => 'latest',
        directory => $path,
        origin    => 'https://gerrit.wikimedia.org/r/p/analytics/refinery/source.git',
        owner     => $user,
        group     => $group,
        mode      => '0755',
        require   => File[$path],
    }
}

# == Class role::analytics::refinery::guard
# Configures a cron job that runs analytics/refinery/source guards daily and
# sends out an email upon issues
#
class role::analytics::refinery::guard {
    require role::analytics::refinery::source

    include ::maven

    cron { 'refinery source guard':
        command     => "${role::analytics::refinery::source::path}/guard/run_all_guards.sh --rebuild-jar --quiet",
        environment => 'MAILTO=otto@wikimedia.org',
        user        => $role::analytics::refinery::source::user,
        hour        => 15,
        minute      => 35,
    }
}
