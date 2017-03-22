# == Class role::analytics_cluster::refinery::job::data_drop
# Installs cron job to drop old hive partitions
# and delete old data from HDFS.
#
class role::analytics_cluster::refinery::job::data_drop {
    require ::role::analytics_cluster::refinery

    $webrequest_log_file     = "${role::analytics_cluster::refinery::log_dir}/drop-webrequest-partitions.log"
    $eventlogging_log_file   = "${role::analytics_cluster::refinery::log_dir}/drop-eventlogging-partitions.log"
    $wdqs_extract_log_file   = "${role::analytics_cluster::refinery::log_dir}/drop-wdqs-extract-partitions.log"
    $mediawiki_log_file      = "${role::analytics_cluster::refinery::log_dir}/drop-mediawiki-log-partitions.log"

    # Shortcut var to DRY up cron commands.
    $env = "export PYTHONPATH=\${PYTHONPATH}:${role::analytics_cluster::refinery::path}/python"

    # Keep this many days of raw webrequest data.
    $raw_retention_days = 31
    cron { 'refinery-drop-webrequest-raw-partitions':
        command => "${env} && ${role::analytics_cluster::refinery::path}/bin/refinery-drop-webrequest-partitions -d ${raw_retention_days} -D wmf_raw -l /wmf/data/raw/webrequest -w raw >> ${webrequest_log_file} 2>&1",
        user    => 'hdfs',
        minute  => '15',
        hour    => '*/4',
    }

    # Keep this many days of refined webrequest data.
    $refined_retention_days = 62
    cron { 'refinery-drop-webrequest-refined-partitions':
        command => "${env} && ${role::analytics_cluster::refinery::path}/bin/refinery-drop-webrequest-partitions -d ${refined_retention_days} -D wmf -l /wmf/data/wmf/webrequest -w refined >> ${webrequest_log_file} 2>&1",
        user    => 'hdfs',
        minute  => '45',
        hour    => '*/4',
    }

    # Keep this many days of eventlogging data.
    $eventlogging_retention_days = 90
    cron {'refinery-drop-eventlogging-partitions':
        command => "${env} && ${role::analytics_cluster::refinery::path}/bin/refinery-drop-eventlogging-partitions -d ${eventlogging_retention_days} -l /wmf/data/raw/eventlogging >> ${eventlogging_log_file} 2>&1",
        user    => 'hdfs',
        minute  => '15',
        hour    => '*/4',
    }

    # keep this many days of wdqs_extract data
    $wdqs_extract_retention_days = 90
    cron {'refinery-drop-wdqs-extract-partitions':
        command => "${env} && ${role::analytics_cluster::refinery::path}/bin/refinery-drop-hourly-partitions -d ${wdqs_extract_retention_days} -p hive -D wmf -t wdqs_extract -l /wmf/data/wmf/wdqs_extract >> ${wdqs_extract_log_file} 2>&1",
        user    => 'hdfs',
        minute  => '0',
        hour    => '1',
    }

    # keep this many days of mediawiki application logs
    $mediawiki_log_retention_days = 90
    cron {'refinery-drop-apiaction-partitions':
        command => "export PYTHONPATH=\${PYTHONPATH}:${role::analytics_cluster::refinery::path}/python && ${role::analytics_cluster::refinery::path}/bin/refinery-drop-hourly-partitions -d ${mediawiki_log_retention_days} -D wmf_raw -t apiaction -p camus -l /wmf/data/raw/mediawiki/mediawiki_ApiAction/hourly >> ${mediawiki_log_file} 2>&1",
        user    => 'hdfs',
        minute  => '15',
        hour    => '*/4',
    }
    cron {'refinery-drop-cirrussearchrequestset-partitions':
        command => "export PYTHONPATH=\${PYTHONPATH}:${role::analytics_cluster::refinery::path}/python && ${role::analytics_cluster::refinery::path}/bin/refinery-drop-hourly-partitions -d ${mediawiki_log_retention_days} -D wmf_raw -t cirrussearchrequestset -p camus -l /wmf/data/raw/mediawiki/mediawiki_CirrusSearchRequestSet/hourly >> ${mediawiki_log_file} 2>&1",
        user    => 'hdfs',
        minute  => '25',
        hour    => '*/4',
    }
}
