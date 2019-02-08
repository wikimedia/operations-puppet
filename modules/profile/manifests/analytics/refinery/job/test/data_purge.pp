# == Class profile::analytics::refinery::job::test::data_purge
#
# Installs cron job to drop old hive partitions,
# delete old data from HDFS (Testing cluster)
#
class profile::analytics::refinery::job::test::data_purge {
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
        command     => "${refinery_path}/bin/refinery-drop-webrequest-partitions -d ${raw_retention_days} -D wmf_raw -l /wmf/data/raw/test-webrequest -w raw",
        interval    => '*-*-* 00/4:15:00',
        environment => $systemd_env,
        user        => 'hdfs',
    }

    # Keep this many days of refined webrequest data.
    $refined_retention_days = 90
    profile::analytics::systemd_timer { 'refinery-drop-webrequest-refined-partitions':
        description => 'Drop Webrequest refined data imported on HDFS following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-webrequest-partitions -d ${refined_retention_days} -D wmf -l /wmf/data/wmf/test-webrequest -w refined",
        interval    => '*-*-* 00/4:45:00',
        environment => $systemd_env,
        user        => 'hdfs',
    }

    # keep this many days of druid webrequest sampled
    # Currently being tested as systemd timer, see below
    $druid_webrequest_sampled_retention_days = 60
    profile::analytics::systemd_timer { 'refinery-drop-webrequest-sampled-druid':
        description => 'Drop Druid Webrequest sampled data from deep storage following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-druid-deep-storage-data --druid-host analytics1041.eqiad.wmnet -d ${druid_webrequest_sampled_retention_days} webrequest_sampled_128",
        interval    => '*-*-* 05:15:00',
        environment => $systemd_env,
        user        => 'hdfs',
    }
}
