# == Class profile::analytics::refinery::job::data_purge
#
# Installs cron job to drop old hive partitions,
# delete old data from HDFS and sanitize EventLogging data.
#
# [*deploy_jobs*]
#   Temporary flag to avoid deploying jobs on new hosts.
#   Default: true
#
class profile::analytics::refinery::job::data_purge (
    $public_druid_host = hiera('profile::analytics::refinery::job::data_purge::public_druid_host', undef),
) {
    require ::profile::analytics::refinery

    $mediawiki_private_log_file      = "${profile::analytics::refinery::log_dir}/drop-mediawiki-private-partitions.log"
    $geoeditors_log_file             = "${profile::analytics::refinery::log_dir}/drop-geoeditor-daily-partitions.log"
    $query_clicks_log_file           = "${profile::analytics::refinery::log_dir}/drop-query-clicks.log"
    $public_druid_snapshots_log_file = "${profile::analytics::refinery::log_dir}/drop-druid-public-snapshots.log"

    # Shortcut to refinery path
    $refinery_path = $profile::analytics::refinery::path

    # Shortcut var to DRY up cron commands.
    $env = "export PYTHONPATH=\${PYTHONPATH}:${refinery_path}/python"
    $systemd_env = {
        'PYTHONPATH' => "\${PYTHONPATH}:${refinery_path}/python",
    }

    # Send an email to analytics in case of failure
    $mail_to = 'analytics-alerts@wikimedia.org'

    # Keep this many days of raw webrequest data.
    $raw_retention_days = 31
    profile::analytics::systemd_timer { 'refinery-drop-webrequest-raw-partitions':
        description => 'Drop Webrequest raw data imported on HDFS following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-webrequest-partitions -d ${raw_retention_days} -D wmf_raw -l /wmf/data/raw/webrequest -w raw",
        interval    => '*-*-* 00/4:15:00',
        environment => $systemd_env,
        user        => 'hdfs',
    }

    # Keep this many days of refined webrequest data.
    $refined_retention_days = 90
    profile::analytics::systemd_timer { 'refinery-drop-webrequest-refined-partitions':
        description => 'Drop Webrequest refined data imported on HDFS following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-webrequest-partitions -d ${refined_retention_days} -D wmf -l /wmf/data/wmf/webrequest -w refined",
        interval    => '*-*-* 00/4:45:00',
        environment => $systemd_env,
        user        => 'hdfs',
    }

    # Keep this many days of eventlogging data.
    $eventlogging_retention_days = 90
    profile::analytics::systemd_timer { 'refinery-drop-eventlogging-partitions':
        description => 'Drop Eventlogging data imported on HDFS following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-eventlogging-partitions -d ${eventlogging_retention_days} -l /wmf/data/raw/eventlogging",
        interval    => '*-*-* 00/4:15:00',
        environment => $systemd_env,
        user        => 'hdfs',
    }

    profile::analytics::systemd_timer { 'refinery-drop-eventlogging-client-side-partitions':
        description => 'Drop Eventlogging Client Side data imported on HDFS following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-eventlogging-partitions -d ${eventlogging_retention_days} -l /wmf/data/raw/eventlogging_client_side",
        interval    => '*-*-* 00/4:30:00',
        environment => $systemd_env,
        user        => 'hdfs',
    }

    # keep this many days of wdqs_extract data
    $wdqs_extract_retention_days = 90
    profile::analytics::systemd_timer { 'refinery-drop-wdqs-extract-partitions':
        description => 'Drop WDQS data imported on HDFS following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-hourly-partitions -d ${wdqs_extract_retention_days} -p hive -D wmf -t wdqs_extract -l /wmf/data/wmf/wdqs_extract",
        interval    => '*-*-* 01:00:00',
        environment => $systemd_env,
        user        => 'hdfs',
    }

    # keep this many days of mediawiki application logs
    $mediawiki_log_retention_days = 90
    profile::analytics::systemd_timer { 'refinery-drop-apiaction-partitions':
        description => 'Drop API action data imported on HDFS following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-hourly-partitions -d ${mediawiki_log_retention_days} -D wmf_raw -t apiaction -p camus -l /wmf/data/raw/mediawiki/mediawiki_ApiAction/hourly",
        interval    => '*-*-* 00/4:15:00',
        environment => $systemd_env,
        user        => 'hdfs',
    }

    profile::analytics::systemd_timer { 'refinery-drop-cirrussearchrequestset-partitions':
        description => 'Drop CirrusSearch request data imported on HDFS following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-hourly-partitions -d ${mediawiki_log_retention_days} -D wmf_raw -t cirrussearchrequestset -p camus -l /wmf/data/raw/mediawiki/mediawiki_CirrusSearchRequestSet/hourly",
        interval    => '*-*-* 00/4:25:00',
        environment => $systemd_env,
        user        => 'hdfs',
    }

    # keep this many days of druid webrequest sampled
    # Currently being tested as systemd timer, see below
    $druid_webrequest_sampled_retention_days = 60
    profile::analytics::systemd_timer { 'refinery-drop-webrequest-sampled-druid':
        description => 'Drop Druid Webrequest sampled data from deep storage following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-druid-deep-storage-data -d ${druid_webrequest_sampled_retention_days} webrequest_sampled_128",
        interval    => '*-*-* 05:15:00',
        environment => $systemd_env,
        user        => 'hdfs',
    }


    # keep this many public druid mediawiki history refined snapshots
    # cron runs once a month
    if $public_druid_host {
        $druid_public_keep_snapshots = 4
        $mediawiki_history_reduced_basename = 'mediawiki_history_reduced'
        profile::analytics::systemd_timer { 'refinery-druid-drop-public-snapshots':
            description => 'Drop Druid Public snapshots from deep storage following data retention policies.',
            command     => "${refinery_path}/bin/refinery-drop-druid-snapshots -d ${mediawiki_history_reduced_basename} -t ${public_druid_host} -s ${druid_public_keep_snapshots} -f ${public_druid_snapshots_log_file}",
            environment => $systemd_env,
            interval    => '*-*-15 07:00:00',
            user        => 'hdfs',
        }
    }

    # keep this many mediawiki history snapshots, 6 minimum
    # cron runs once a month
    $keep_snapshots = 6
    profile::analytics::systemd_timer { 'mediawiki-history-drop-snapshot':
        description => 'Drop Druid Mediawiki History snapshots from deep storage following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-mediawiki-snapshots -s ${keep_snapshots}",
        environment => $systemd_env,
        interval    => '*-*-15 06:15:00',
        user        => 'hdfs',
    }

    # keep this many days of banner activity success files
    # cron runs once a day
    $banner_activity_retention_days = 90
    profile::analytics::systemd_timer { 'refinery-drop-banner-activity':
        description => 'Drop Druid Banner Activity from deep storage following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-banner-activity-partitions -d ${banner_activity_retention_days} -l /wmf/data/wmf/banner_activity",
        environment => $systemd_env,
        interval    => '*-*-* 02:00:00',
        user        => 'hdfs',
    }

    # create and rotate cryptographic salts for EventLogging sanitization
    # cron runs once a day, at midnight, to coincide with salt rotation time
    # given that hdfs stores modified dates without milliseconds
    # 1 minute margin is given to avoid timestamp comparison problems
    profile::analytics::systemd_timer { 'refinery-eventlogging-saltrotate':
        description => 'Create and rotate cryptographic salts for EventLogging sanitization.',
        command     => "${refinery_path}/bin/saltrotate --verbose -p '3 months' -b '14 days' /user/hdfs/eventlogging-sanitization-salt.txt",
        environment => $systemd_env,
        interval    => '*-*-* 01:00:00',
        user        => 'hdfs',
    }

    # Sanitize event database into event_sanitized.
    # Cron job runs once an hour.  EventLoggingSanitization is a Refine job wrapper with
    # some extra features.  Use refine_job to configure and run it.
    profile::analytics::refinery::job::refine_job { 'sanitize_eventlogging_analytics':
        job_name            => 'sanitize_eventlogging_analytics',
        job_class           => 'org.wikimedia.analytics.refinery.job.refine.EventLoggingSanitization',
        monitor_class       => 'org.wikimedia.analytics.refinery.job.refine.EventLoggingSanitizationMonitor',
        job_config          => {
            'input_path'          => '/wmf/data/event',
            'database'            => 'event_sanitized',
            'output_path'         => '/wmf/data/event_sanitized',
            'whitelist_path'      => '/wmf/refinery/current/static_data/eventlogging/whitelist.yaml',
            'salt_path'           => '/user/hdfs/eventlogging-sanitization-salt.txt',
            'parallelism'         => '16',
            'should_email_report' => true,
            'emails_to'           => 'analytics-alerts@wikimedia.org',
        },
        spark_driver_memory => '16G',
        spark_max_executors => '128',
        spark_extra_opts    => '--conf spark.ui.retainedStage=20 --conf spark.ui.retainedTasks=1000 --conf spark.ui.retainedJobs=100',
        monitoring_enabled  => false,
        minute              => 0,
    }


    # drop data older than 2 months from cu_changes table, which is sqooped in
    # cron runs once a month
    $geoeditors_private_retention_days = 80
    profile::analytics::systemd_timer { 'mediawiki-raw-cu-changes-drop-month':
        description => 'Drop raw Mediawiki cu_changes from Hive/HDFS following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-hive-partitions -d ${geoeditors_private_retention_days} -D wmf_raw -t mediawiki_private_cu_changes -l 1 -f ${mediawiki_private_log_file}",
        environment => $systemd_env,
        interval    => '*-*-16 05:00:00',
        user        => 'hdfs',
    }

    # drop data older than 2 months from geoeditors_daily table
    # cron runs once a month
    profile::analytics::systemd_timer { 'mediawiki-geoeditors-drop-month':
        description => 'Drop Geo-editors data from Hive/HDFS following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-hive-partitions -d ${geoeditors_private_retention_days} -D wmf -t geoeditors_daily -l 1 -f ${geoeditors_log_file}",
        environment => $systemd_env,
        interval    => '*-*-16 06:00:00',
        user        => 'hdfs',
    }

    # keep this many days of search query click files
    # cron runs once a day
    $query_click_retention_days = 90
    cron {'refinery-drop-query-clicks':
        command     => "${env} && ${profile::analytics::refinery::path}/bin/refinery-drop-hive-partitions -d ${query_click_retention_days} -D discovery -t query_clicks_hourly,query_clicks_daily >> ${query_clicks_log_file}",
        environment => 'MAILTO=discovery-alerts@lists.wikimedia.org',
        user        => 'hdfs',
        minute      => '30',
        hour        => '3',
    }

}
