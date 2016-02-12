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
