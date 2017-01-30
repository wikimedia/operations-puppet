# == Class role::analytics_cluster::refinery::data::drop
# Installs cron job to drop old hive partitions
# and delete old data from HDFS.
#
class role::analytics_cluster::refinery::data::drop {
    require ::role::analytics_cluster::refinery

    $webrequest_log_file     = "${role::analytics_cluster::refinery::log_dir}/drop-webrequest-partitions.log"
    $eventlogging_log_file   = "${role::analytics_cluster::refinery::log_dir}/drop-eventlogging-partitions.log"
    $mediawiki_log_file      = "${role::analytics_cluster::refinery::log_dir}/drop-mediawiki-partitions.log"

    # keep this many days of raw webrequest data
    $raw_retention_days = 31
    cron { 'refinery-drop-webrequest-raw-partitions':
        command => "export PYTHONPATH=\${PYTHONPATH}:${role::analytics_cluster::refinery::path}/python && ${role::analytics_cluster::refinery::path}/bin/refinery-drop-webrequest-partitions -d ${raw_retention_days} -D wmf_raw -l /wmf/data/raw/webrequest -w raw >> ${webrequest_log_file} 2>&1",
        user    => 'hdfs',
        minute  => '15',
        hour    => '*/4',
    }

    # keep this many days of refined webrequest data
    $refined_retention_days = 62
    cron { 'refinery-drop-webrequest-refined-partitions':
        command => "export PYTHONPATH=\${PYTHONPATH}:${role::analytics_cluster::refinery::path}/python && ${role::analytics_cluster::refinery::path}/bin/refinery-drop-webrequest-partitions -d ${refined_retention_days} -D wmf -l /wmf/data/wmf/webrequest -w refined >> ${webrequest_log_file} 2>&1",
        user    => 'hdfs',
        minute  => '45',
        hour    => '*/4',
    }

    # keep this many days of eventlogging data
    $eventlogging_retention_days = 90
    cron {'refinery-drop-eventlogging-partitions':
        command => "export PYTHONPATH=\${PYTHONPATH}:${role::analytics_cluster::refinery::path}/python && ${role::analytics_cluster::refinery::path}/bin/refinery-drop-eventlogging-partitions -d ${eventlogging_retention_days} -l /wmf/data/raw/eventlogging >> ${eventlogging_log_file} 2>&1",
        user    => 'hdfs',
        minute  => '15',
        hour    => '*/4',
    }

    $mediawiki_retention_days = 90
    ['CirrusSearchRequestSet', 'ApiAction'].each |log_type| do
        cron {"refinery-drop-${type}-partitions":
            command => "export PYTHONPATH=\${PYTHONPATH}:${role::analytics_cluster::refinery::path}/python && ${role::analytics_cluster::refinery::path}/bin/refinery-drop-eventlogging-partitions -d ${mediawiki_retention_days} -l /wmf/data/raw/mediawiki/mediawiki_${log_type} >> ${mediawiki_log_file} 2>&1",
            user    => 'hdfs',
            minute  => '15',
            hour    => '*/4',
        }
    end
}
