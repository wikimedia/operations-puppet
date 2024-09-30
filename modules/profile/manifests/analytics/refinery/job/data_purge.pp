# SPDX-License-Identifier: Apache-2.0
# == Class profile::analytics::refinery::job::data_purge
#
# Installs systemd-timer jobs to drop old hive partitions,
# delete old data from HDFS and sanitize EventLogging data.
#
# [*deploy_jobs*]
#   Temporary flag to avoid deploying jobs on new hosts.
#   Default: true
#
class profile::analytics::refinery::job::data_purge (
    Optional[String] $public_druid_host = lookup('profile::analytics::refinery::job::data_purge::public_druid_host', { 'default_value' => undef }),
    Wmflib::Ensure $ensure_timers       = lookup('profile::analytics::refinery::job::data_purge::ensure_timers', { 'default_value' => 'present' }),
    Boolean $use_kerberos_keytab        = lookup('profile::analytics::refinery::job::data_purge::use_kerberos_keytab', { 'default_value' => true }),
) {
    require ::profile::analytics::refinery

    $query_clicks_log_file           = "${profile::analytics::refinery::log_dir}/drop-query-clicks.log"
    $public_druid_snapshots_log_file = "${profile::analytics::refinery::log_dir}/drop-druid-public-snapshots.log"
    $mediawiki_dumps_log_file        = "${profile::analytics::refinery::log_dir}/drop-mediawiki-dumps.log"
    $el_unsanitized_log_file         = "${profile::analytics::refinery::log_dir}/drop-el-unsanitized-events.log"

    # Shortcut to refinery path
    $refinery_path = $profile::analytics::refinery::path

    # Shortcut var to DRY up commands.
    $env = "export PYTHONPATH=\${PYTHONPATH}:${refinery_path}/python"
    $systemd_env = {
        'PYTHONPATH' => "\${PYTHONPATH}:${refinery_path}/python",
    }

    # Send an email to analytics in case of failure
    $mail_to = 'data-engineering-alerts@wikimedia.org'

    # Conventional Hive format path with partition keys (used by Gobblin), i.e. year=yyyy/month=mm/day=dd/hour=hh.
    $hive_date_path_format = 'year=(?P<year>[0-9]+)(/month=(?P<month>[0-9]+)(/day=(?P<day>[0-9]+)(/hour=(?P<hour>[0-9]+))?)?)?'

    # Most jobs will use this retention_days period.
    $retention_days = 90

    # Keep this many days of raw webrequest data.
    $webrequest_raw_retention_days = 31
    kerberos::systemd_timer { 'refinery-drop-webrequest-raw-partitions':
        ensure      => $ensure_timers,
        description => 'Drop Webrequest raw data imported on HDFS following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --database='wmf_raw' --tables='webrequest' --base-path='/wmf/data/raw/webrequest' --path-format='.+/${hive_date_path_format}' --older-than='${webrequest_raw_retention_days}' --allowed-interval='3' --skip-trash --execute='1174bbc96c9b1cee08bc20b3544b1c7f'",
        interval    => '*-*-* 00/4:15:00',
        environment => $systemd_env,
        user        => 'analytics',
    }

    # Keep this many days of data for analysis on some datasets relative to unique devices.
    # This value has been extended to 180 days to allow for analysis of long-term trends and in accordance with the
    # privacy team. https://phabricator.wikimedia.org/T373630
    # Revert to 90 days after the analysis is done.
    $long_term_analysis_retention_days = 180

    kerberos::systemd_timer { 'refinery-drop-webrequest-refined-partitions':
        ensure      => $ensure_timers,
        description => 'Drop Webrequest refined data imported on HDFS following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --database='wmf' --tables='webrequest' --base-path='/wmf/data/wmf/webrequest' --path-format='.+/${hive_date_path_format}' --older-than='${long_term_analysis_retention_days}' --allowed-interval='3' --skip-trash --execute='aab323f301c0660e7e0976d773c3201b'",
        interval    => '*-*-* 00/4:45:00',
        environment => $systemd_env,
        user        => 'analytics',
    }

    # Keep this many days of webrequest sequence stats data (400 days =~ 13 months) .
    $webrequest_sequence_stats_retention_days = 400
    kerberos::systemd_timer { 'refinery-drop-webrequest-sequence-stats-partitions':
        ensure      => $ensure_timers,
        description => 'Drop Webrequest sequence stats (detailed and hourly) from HDFS to prevent small-files number to grow.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --database='wmf_raw' --tables='^webrequest_sequence_stats(_hourly)?$' --older-than='${webrequest_sequence_stats_retention_days}' --allowed-interval='3' --skip-trash --execute='e10b61944570ec55829f632d81538256'",
        interval    => '*-*-* 00:30:00',
        environment => $systemd_env,
        user        => 'analytics',
    }

    # Webrequest data loss path format in HDFS, i.e.:
    #   - base_path/webrequest_source/Y/M/D/H/level (time parts are not padded)
    #   - /wmf/data/raw/webrequests_data_loss/test_text/2023/4/13/8/WARNING
    $hive_webrequest_data_loss_path_format = '((upload|text|test_text)(/(?P<year>[0-9]+)(/(?P<month>[0-9]+)(/(?P<day>[0-9]+)(/(?P<hour>[0-9]+)(/(WARNING|ERROR))?)?)?)?)?)?'
    kerberos::systemd_timer { 'refinery-drop-webrequest-dataloss-reports':
      ensure      => $ensure_timers,
      description => 'Drop Webrequest dataloss reports (hourly) from HDFS to prevent small-files number to grow.',
      command     => "${refinery_path}/bin/refinery-drop-older-than --older-than='${webrequest_sequence_stats_retention_days}' --allowed-interval='9999' --skip-trash --execute='f3177d27cf2e183cb5da2191c6974280' --base-path='/wmf/data/raw/webrequests_data_loss' --path-format='${hive_webrequest_data_loss_path_format}'",
      interval    => '*-*-* 00:40:00',  # daily at 00:40
      environment => $systemd_env,
      user        => 'analytics',
    }

    kerberos::systemd_timer { 'refinery-drop-pageview-actor-hourly-partitions':
        ensure      => $ensure_timers,
        description => 'Drop pageview_actor_hourly data from HDFS following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --database='wmf' --tables='pageview_actor' --base-path='/wmf/data/wmf/pageview/actor' --path-format='${hive_date_path_format}' --older-than='${long_term_analysis_retention_days}' --allowed-interval='3' --skip-trash --execute='264d06ccd4b5ca2f036bbfbf1c33ef8a'",
        interval    => '*-*-* 00/4:50:00',
        environment => $systemd_env,
        user        => 'analytics',
    }

    # Note on --allowed-interval for this job: There's an issue with raw events
    # collection (https://phabricator.wikimedia.org/T282887), that generates
    # data directories with old time partition specs (year=2015). Thus we can not use
    # --allowed-interval='3' as we would expect, since it would make the script fail when
    # detecting old data. Also, we can not ommit the --allowed-interval parameter,
    # since it's mandatory. So we pass a large number (9999 = 27y) to it.
    # Once the issue with data collection is fixed, we can add the proper allowed interval.
    kerberos::systemd_timer { 'refinery-drop-raw-event':
        ensure      => $ensure_timers,
        description => 'Drop raw event (/wmf/data/raw/event) data imported on HDFS following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --base-path='/wmf/data/raw/event' --path-format='.+/${hive_date_path_format}' --older-than='${retention_days}' --allowed-interval='9999' --skip-trash --execute='440faa6a6392696b483903d2d9e20e33'",
        interval    => '*-*-* 00/4:20:00',
        environment => $systemd_env,
        user        => 'analytics',
    }

    # netflow events are imported separately from regular events, so they need their own purge job.
    kerberos::systemd_timer { 'refinery-drop-raw-netflow-event':
        ensure      => $ensure_timers,
        description => 'Drop raw netflow event (/wmf/data/raw/netflow) data imported on HDFS following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --base-path='/wmf/data/raw/netflow' --path-format='[^/]+/${hive_date_path_format}' --older-than='${retention_days}' --allowed-interval='3' --skip-trash --execute='60f6dee92d136227aa56995f5ede20da'",
        interval    => '*-*-* 00/4:35:00',
        environment => $systemd_env,
        user        => 'analytics',
    }

    # Drop old data from all tables in the Hive event database with tables in /wmf/data/event.
    # Data that should be kept indefinitely is sanitized by refine_sanitize jobs into the
    # event_sanitized Hive database, so all data older than 90 days should be safe to drop.
    $drop_event_log_file = "${profile::analytics::refinery::log_dir}/drop_event.log"
    kerberos::systemd_timer { 'drop_event':
        description => 'Drop data in Hive event database older than 90 days.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --database='event' --tables='.*' --base-path='/wmf/data/event' --path-format='[^/]+(/datacenter=[^/]+)?/${hive_date_path_format}' --older-than='${retention_days}' --allowed-interval='3' --execute='0586baac1a9b1439fd361f9aae8af698' --log-file='${drop_event_log_file}'",
        interval    => '*-*-* 00:00:00',
        # An issue with hive-log4j and timers was causing errors when the Hive CLI was being
        # used by the same users at the same time.  We should eventually stop shelling out
        # to the Hive CLI in refinery-drop-older-than, but for now this works around
        # the problem by using a dedicated Hive CLI log file (in /tmp/analytics) for this job.
        # See /etc/hive/conf/hive-log4j.conf for more info.
        # https://phabricator.wikimedia.org/T283126
        environment => $systemd_env.merge({'HADOOP_CLIENT_OPTS' => '-Dhive.log.file=hive-drop_event.log'}),
        user        => 'analytics',
    }

    kerberos::systemd_timer { 'refinery-drop-eventlogging-legacy-raw-partitions':
        ensure      => $ensure_timers,
        description => 'Drop Eventlogging legacy raw (/wmf/data/raw/eventlogging_legacy) data imported on HDFS following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --base-path='/wmf/data/raw/eventlogging_legacy' --path-format='.+/${hive_date_path_format}' --older-than='${retention_days}' --allowed-interval='3' --skip-trash --execute='838981ec29cc2288979559bb27074eb2'",
        interval    => '*-*-* 00/4:15:00',
        environment => $systemd_env,
        user        => 'analytics',
    }

    # Keep this many days of druid webrequest sampled
    # Please note: we are currently setting a custom loadPolicy of (now-30 days)
    # in Druid (for more info, check the Coordinator's UI -> Datasources -> ..)
    # that limits the segments pulled by Druid from deep storage.
    # The value defined below is related only to the retention period for
    # the Druid segments stored in deep storage.
    $druid_webrequest_sampled_retention_days = 60
    kerberos::systemd_timer { 'refinery-drop-webrequest-sampled-druid':
        ensure      => $ensure_timers,
        description => 'Drop Druid Webrequest sampled data from deep storage following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-druid-deep-storage-data -d ${druid_webrequest_sampled_retention_days} webrequest_sampled_128",
        interval    => '*-*-* 05:15:00',
        environment => $systemd_env,
        user        => 'analytics',
    }

    # In T337460 we are trying to ramp up the webrequest sample live
    # retention to 30 days as well. The goal is to eventually deprecate
    # the webrequest-sampled-128 datasource in Druid.
    # Hence we keep the same retention rules for the live datasource.
    kerberos::systemd_timer { 'refinery-drop-webrequest-sampled-live-druid':
        ensure      => $ensure_timers,
        description => 'Drop Druid Webrequest sampled live data from deep storage following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-druid-deep-storage-data -d ${druid_webrequest_sampled_retention_days} webrequest_sampled_live",
        interval    => '*-*-* 05:30:00',
        environment => $systemd_env,
        user        => 'analytics',
    }

    # keep this many public druid mediawiki history refined snapshots
    # runs once a month
    if $public_druid_host {
        $druid_public_keep_snapshots = 3
        $mediawiki_history_reduced_basename = 'mediawiki_history_reduced'
        kerberos::systemd_timer { 'refinery-druid-drop-public-snapshots':
            ensure      => $ensure_timers,
            description => 'Drop Druid Public snapshots from deep storage following data retention policies.',
            command     => "${refinery_path}/bin/refinery-drop-druid-snapshots -d ${mediawiki_history_reduced_basename} -t ${public_druid_host} -s ${druid_public_keep_snapshots} -f ${public_druid_snapshots_log_file}",
            environment => $systemd_env,
            interval    => 'Mon,Tue,Wed,Thu,Fri *-*-15 09:00:00',
            user        => 'analytics',
        }
    }

    # Purge snapshots keeping only last 6 (except wmf.mediawiki_wikitext_history, keeping 2):
    #  wmf_raw.mediawiki_archive
    #  wmf_raw.mediawiki_change_tag
    #  wmf_raw.mediawiki_ipblocks
    #  wmf_raw.mediawiki_logging
    #  wmf_raw.mediawiki_page
    #  wmf_raw.mediawiki_pagelinks
    #  wmf_raw.mediawiki_project_namespace_map
    #  wmf_raw.mediawiki_redirect
    #  wmf_raw.mediawiki_revision
    #  wmf_raw.mediawiki_user
    #  wmf_raw.mediaiki_user_groups
    #
    #  wmf.mediawiki_history
    #  wmf.mediawiki_metrics
    #  wmf.mediawiki_page_history
    #  wmf.mediawiki_user_history
    #  wmf.mediawiki_history_reduced
    #  wmf.edit_hourly
    #  wmf.mediawiki_wikitext_history
    #  wmf.mediawiki_wikitext_current
    #  wmf.wikidata_entity
    #  wmf.wikidata_item_page_link
    #
    # runs twice a month on the 15th and 30th
    # (30th is to drop wikitext fast as it gets released at the end of the month)
    kerberos::systemd_timer { 'mediawiki-history-drop-snapshot':
        ensure      => $ensure_timers,
        description => 'Drop snapshots from multiple raw and refined mediawiki datasets, configured in the refinery-drop script.',
        command     => "${refinery_path}/bin/refinery-drop-mediawiki-snapshots",
        environment => $systemd_env,
        interval    => '*-*-15,30 06:15:00',
        user        => 'analytics',
    }

    # Delete mediawiki history dump snapshots older than 6 months.
    # Runs on the first day of each month. This way it frees up space for the new snapshot.
    $mediawiki_history_dumps_retention_days = 180
    kerberos::systemd_timer { 'refinery-drop-mediawiki-history-dumps':
        ensure      => $ensure_timers,
        description => 'Drop mediawiki history dump versions older than 6 months.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --base-path='/wmf/data/archive/mediawiki/history' --path-format='(?P<year>[0-9]+)-(?P<month>[0-9]+)' --older-than='${mediawiki_history_dumps_retention_days}' --allowed-interval='70' --skip-trash --execute='a189ad0d21601b27cb14b0b1c9ba0297'",
        interval    => '*-*-01 00:00:00',
        environment => $systemd_env,
        user        => 'analytics',
    }

    # keep this many days of banner activity success files
    # runs once a day
    $banner_activity_retention_days = 90
    kerberos::systemd_timer { 'refinery-drop-banner-activity':
        ensure      => $ensure_timers,
        description => 'Clean old Banner Activity _SUCCESS flags from HDFS.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --base-path='/wmf/data/wmf/banner_activity' --path-format='daily/year=(?P<year>[0-9]+)(/month=(?P<month>[0-9]+)(/day=(?P<day>[0-9]+))?)?' --older-than='${banner_activity_retention_days}' --allowed-interval='3' --skip-trash --execute='8040ed60791cc74e9c8cc2d72780cb94'",
        environment => $systemd_env,
        interval    => '*-*-* 02:00:00',
        user        => 'analytics',
    }

    # runs once a day (but only will delete data on the needed date)
    $geoeditors_private_retention_days = 60
    kerberos::systemd_timer { 'mediawiki-raw-cu-changes-drop-month':
        ensure      => $ensure_timers,
        description => 'Drop raw MediaWiki cu_changes from Hive/HDFS following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --database='wmf_raw' --tables='mediawiki_private_cu_changes' --base-path='/wmf/data/raw/mediawiki_private/tables/cu_changes' --path-format='month=(?P<year>[0-9]+)-(?P<month>[0-9]+)' --older-than='${geoeditors_private_retention_days}' --allowed-interval='70' --skip-trash --execute='c4f2dff98baa1d188ee22b5b90d7fad6'",
        environment => $systemd_env,
        interval    => '*-*-* 05:00:00',
        user        => 'analytics',
    }
    # drop data older than 2-3 months from editors_daily table
    # runs once a day (but only will delete data on the needed date)
    kerberos::systemd_timer { 'mediawiki-editors-drop-month':
        ensure      => $ensure_timers,
        description => 'Drop editors data, primarily used for the geoeditors dataset, from Hive/HDFS following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --database='wmf' --tables='editors_daily' --base-path='/wmf/data/wmf/mediawiki_private/editors_daily' --path-format='month=(?P<year>[0-9]+)-(?P<month>[0-9]+)' --older-than='${geoeditors_private_retention_days}' --allowed-interval='70' --skip-trash --execute='fafa458b9141f12be3efd7a9af8afb2b'",
        environment => $systemd_env,
        interval    => '*-*-* 06:00:00',
        user        => 'analytics',
    }

    # drop monthly pages_meta_history dumps data after 80 days (last day of month as reference)
    # runs once a month
    $dumps_retention_days = 80
    kerberos::systemd_timer { 'drop-mediawiki-pages_meta_history-dumps':
        ensure      => $ensure_timers,
        description => 'Drop pages_meta_history dumps data from HDFS after 80 days.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --base-path /wmf/data/raw/mediawiki/dumps/pages_meta_history --path-format '(?P<year>[0-9]{4})(?P<month>[0-9]{2})01' --older-than ${dumps_retention_days} --allowed-interval 70 --log-file ${mediawiki_dumps_log_file} --skip-trash --execute d1ae950b3ddd706bcac0ab068ca8953f",
        environment => $systemd_env,
        interval    => '*-*-20 06:00:00',
        user        => 'analytics',
    }

    # drop monthly pages_meta_current dumps data after 80 days (last day of month as reference)
    # runs once a month
    kerberos::systemd_timer { 'drop-mediawiki-pages_meta_current-dumps':
        ensure      => $ensure_timers,
        description => 'Drop pages_meta_current dumps data from HDFS after 80 days.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --base-path /wmf/data/raw/mediawiki/dumps/pages_meta_current --path-format '(?P<year>[0-9]{4})(?P<month>[0-9]{2})01' --older-than ${dumps_retention_days} --allowed-interval 70 --log-file ${mediawiki_dumps_log_file} --skip-trash --execute 2962f6cd190c2c04bf22e075196a7db1",
        environment => $systemd_env,
        interval    => '*-*-20 07:00:00',
        user        => 'analytics',
    }

    # drop monthly siteinfo_namespaces dumps data after 80 days (last day of month as reference)
    # runs once a month
    kerberos::systemd_timer { 'drop-mediawiki-siteinfo_namespaces-dumps':
        ensure      => $ensure_timers,
        description => 'Drop pages_meta_current dumps data from HDFS after 80 days.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --base-path /wmf/data/raw/mediawiki/dumps/siteinfo_namespaces --path-format '(?P<year>[0-9]{4})(?P<month>[0-9]{2})01' --older-than ${dumps_retention_days} --allowed-interval 70 --log-file ${mediawiki_dumps_log_file} --skip-trash --execute f6f65f154c151526af100fdb6542b44e",
        environment => $systemd_env,
        interval    => '*-*-20 05:00:00',
        user        => 'analytics',
    }

    # drop hourly webrequest_actor data (3 datasets) used to compute automated agent-type after 90 days
        kerberos::systemd_timer { 'drop-webrequest-actor-metrics-hourly':
        ensure      => $ensure_timers,
        description => 'Drop wmf.webrequest_actor_metrics_hourly data from Hive and HDFS after 90 days.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --database='wmf' --tables='webrequest_actor_metrics_hourly' --base-path='/wmf/data/wmf/webrequest_actor/metrics/hourly' --path-format='${hive_date_path_format}' --older-than='${long_term_analysis_retention_days}' --allowed-interval='3' --skip-trash --execute='5f0df64634f68dfd443333877568898d'",
        environment => $systemd_env,
        interval    => '*-*-* 00/4:40:00',
        user        => 'analytics',
    }
    kerberos::systemd_timer { 'drop-webrequest-actor-metrics-rollup-hourly':
        ensure      => $ensure_timers,
        description => 'Drop wmf.webrequest_actor_metrics_rollup_hourly data from Hive and HDFS after 90 days.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --database='wmf' --tables='webrequest_actor_metrics_rollup_hourly' --base-path='/wmf/data/wmf/webrequest_actor/metrics/rollup/hourly' --path-format='${hive_date_path_format}' --older-than='${long_term_analysis_retention_days}' --allowed-interval='3' --skip-trash --execute='b2bf881a21280478bcb63deb9c1708da'",
        environment => $systemd_env,
        interval    => '*-*-* 00/4:45:00',
        user        => 'analytics',
    }
    kerberos::systemd_timer { 'drop-webrequest-actor-label-hourly':
        ensure      => $ensure_timers,
        description => 'Drop wmf.webrequest_actor_label_hourly data from Hive and HDFS after 90 days.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --database='wmf' --tables='webrequest_actor_label_hourly' --base-path='/wmf/data/wmf/webrequest_actor/label/hourly' --path-format='${hive_date_path_format}' --older-than='${long_term_analysis_retention_days}' --allowed-interval='3' --skip-trash --execute='f2cc832c9e98a5f51003be74186a8be8'",
        environment => $systemd_env,
        interval    => '*-*-* 00/4:50:00',
        user        => 'analytics',
    }

    # Drop old anomaly detection data. The retention days are set to 182,
    # because the anomaly detection system groups the data in chunks of 7 days
    # (for weekly seasonality) and 182 is a multiple of 7.
    kerberos::systemd_timer { 'drop-anomaly-detection':
        ensure      => $ensure_timers,
        description => 'Drop wmf.anomaly_detection data from Hive and HDFS after about 6 months.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --database='wmf' --tables='anomaly_detection' --base-path='/wmf/data/wmf/anomaly_detection' --path-format='source=[^/]+/year=(?P<year>[0-9]+)(/month=(?P<month>[0-9]+)(/day=(?P<day>[0-9]+))?)?' --older-than='182' --allowed-interval='3' --execute='898489f6cccfa18848f3eda4c3dc4489'",
        environment => $systemd_env,
        interval    => '*-*-* 02:00:00',
        user        => 'analytics',
    }

    # Drop old data from the image_suggestions data pipeline, which is owned by the analytics-platform-eng user.
    kerberos::systemd_timer { 'drop-image-suggestions':
      ensure      => $ensure_timers,
      description => 'Drop analytics_platform_eng.image_suggestions_.* data from Hive and HDFS after about 45 days.',
      command     => "${refinery_path}/bin/refinery-drop-older-than --database='analytics_platform_eng' --tables='image_suggestions_.*' --older-than='45' --allowed-interval='15' --execute='bd3b6696f27c9f6c718d78115249eb0d'",
      environment => $systemd_env,
      interval    => 'Mon 13:00:00', # Run every monday at 13:00 UTC (8am ET/5am PT)
      user        => 'analytics-platform-eng',
    }
}
