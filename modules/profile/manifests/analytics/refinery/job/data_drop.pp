# == Class profile::analytics::refinery::job::data_drop
# Installs cron job to drop old hive partitions
# and delete old data from HDFS.
#
class profile::analytics::refinery::job::data_drop {
    require ::profile::analytics::refinery

    $webrequest_log_file        = "${profile::analytics::refinery::log_dir}/drop-webrequest-partitions.log"
    $eventlogging_log_file      = "${profile::analytics::refinery::log_dir}/drop-eventlogging-partitions.log"
    $wdqs_extract_log_file      = "${profile::analytics::refinery::log_dir}/drop-wdqs-extract-partitions.log"
    $mediawiki_log_file         = "${profile::analytics::refinery::log_dir}/drop-mediawiki-log-partitions.log"
    $druid_webrequest_log_file  = "${profile::analytics::refinery::log_dir}/drop-druid-webrequest.log"
    $mediawiki_history_log_file = "${profile::analytics::refinery::log_dir}/drop-mediawiki-history.log"
    $banner_activity_log_file   = "${profile::analytics::refinery::log_dir}/drop-banner-activity.log"

    # Shortcut var to DRY up cron commands.
    $env = "export PYTHONPATH=\${PYTHONPATH}:${profile::analytics::refinery::path}/python"

    # Send an email to analytics in case of failure
    $mail_to = 'analytics-alerts@wikimedia.org'

    # Keep this many days of raw webrequest data.
    $raw_retention_days = 31
    cron { 'refinery-drop-webrequest-raw-partitions':
        command => "${env} && ${profile::analytics::refinery::path}/bin/refinery-drop-webrequest-partitions -d ${raw_retention_days} -D wmf_raw -l /wmf/data/raw/webrequest -w raw >> ${webrequest_log_file} 2>&1",
        user    => 'hdfs',
        minute  => '15',
        hour    => '*/4',
    }

    # Keep this many days of refined webrequest data.
    $refined_retention_days = 90
    cron { 'refinery-drop-webrequest-refined-partitions':
        # Temporarily disable webrequest deletion while lawyers do some research (Otto, Dan, Nuria)
        # This should only be disabled for a week or so.
        ensure  => 'absent',
        command => "${env} && ${profile::analytics::refinery::path}/bin/refinery-drop-webrequest-partitions -d ${refined_retention_days} -D wmf -l /wmf/data/wmf/webrequest -w refined >> ${webrequest_log_file} 2>&1",
        user    => 'hdfs',
        minute  => '45',
        hour    => '*/4',
    }

    # Keep this many days of eventlogging data.
    $eventlogging_retention_days = 90
    cron {'refinery-drop-eventlogging-partitions':
        command => "${env} && ${profile::analytics::refinery::path}/bin/refinery-drop-eventlogging-partitions -d ${eventlogging_retention_days} -l /wmf/data/raw/eventlogging >> ${eventlogging_log_file} 2>&1",
        user    => 'hdfs',
        minute  => '15',
        hour    => '*/4',
    }

    # keep this many days of wdqs_extract data
    $wdqs_extract_retention_days = 90
    cron {'refinery-drop-wdqs-extract-partitions':
        command => "${env} && ${profile::analytics::refinery::path}/bin/refinery-drop-hourly-partitions -d ${wdqs_extract_retention_days} -p hive -D wmf -t wdqs_extract -l /wmf/data/wmf/wdqs_extract >> ${wdqs_extract_log_file} 2>&1",
        user    => 'hdfs',
        minute  => '0',
        hour    => '1',
    }

    # keep this many days of mediawiki application logs
    $mediawiki_log_retention_days = 90
    cron {'refinery-drop-apiaction-partitions':
        command => "export PYTHONPATH=\${PYTHONPATH}:${profile::analytics::refinery::path}/python && ${profile::analytics::refinery::path}/bin/refinery-drop-hourly-partitions -d ${mediawiki_log_retention_days} -D wmf_raw -t apiaction -p camus -l /wmf/data/raw/mediawiki/mediawiki_ApiAction/hourly >> ${mediawiki_log_file} 2>&1",
        user    => 'hdfs',
        minute  => '15',
        hour    => '*/4',
    }
    cron {'refinery-drop-cirrussearchrequestset-partitions':
        command => "export PYTHONPATH=\${PYTHONPATH}:${profile::analytics::refinery::path}/python && ${profile::analytics::refinery::path}/bin/refinery-drop-hourly-partitions -d ${mediawiki_log_retention_days} -D wmf_raw -t cirrussearchrequestset -p camus -l /wmf/data/raw/mediawiki/mediawiki_CirrusSearchRequestSet/hourly >> ${mediawiki_log_file} 2>&1",
        user    => 'hdfs',
        minute  => '25',
        hour    => '*/4',
    }
    # keep this many days of druid webrequest sampled
    $druid_webrequest_sampled_retention_days = 60
    cron {'refinery-drop-webrequest-sampled-druid':
        command     => "${env} && ${profile::analytics::refinery::path}/bin/refinery-drop-druid-deep-storage-data -d ${druid_webrequest_sampled_retention_days} webrequest >> ${druid_webrequest_log_file}",
        environment => "MAILTO=${mail_to}",
        user        => 'hdfs',
        minute      => '15',
        hour        => '5'
    }

    # keep this many mediawiki history snapshots, 6 minimum
    # cron runs once a month
    $keep_snapshots = 6
    cron {'mediawiki-history-drop-snapshot':
        command     => "${env} && ${profile::analytics::refinery::path}/bin/refinery-drop-mediawiki-snapshots -s ${keep_snapshots} >> ${mediawiki_history_log_file}",
        environment => "MAILTO=${mail_to}",
        user        => 'hdfs',
        minute      => '0',
        hour        => '6',
        monthday    => '15'
    }

    # keep this many days of banner activity success files
    # cron runs once a day
    $banner_activity_retention_days = 90
    cron {'refinery-drop-banner-activity':
        command     => "${env} && ${profile::analytics::refinery::path}/bin/refinery-drop-banner-activity-partitions -d ${banner_activity_retention_days} -l /wmf/data/wmf/banner_activity >> ${banner_activity_log_file}",
        environment => "MAILTO=${mail_to}",
        user        => 'hdfs',
        minute      => '0',
        hour        => '2',
    }
}
