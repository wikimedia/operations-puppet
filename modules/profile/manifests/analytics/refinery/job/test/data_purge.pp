# == Class profile::analytics::refinery::job::test::data_purge
#
# Installs systemd timers to drop old hive partitions,
# delete old data from HDFS (Testing cluster)
#
class profile::analytics::refinery::job::test::data_purge(
    $use_kerberos = lookup('profile::analytics::refinery::job::test::data_purge::use_kerberos', { 'default_value' => false }),
) {
    require ::profile::analytics::refinery

    $mediawiki_private_log_file      = "${profile::analytics::refinery::log_dir}/drop-mediawiki-private-partitions.log"
    $geoeditors_log_file             = "${profile::analytics::refinery::log_dir}/drop-geoeditor-daily-partitions.log"
    $query_clicks_log_file           = "${profile::analytics::refinery::log_dir}/drop-query-clicks.log"
    $public_druid_snapshots_log_file = "${profile::analytics::refinery::log_dir}/drop-druid-public-snapshots.log"

    # Shortcut to refinery path
    $refinery_path = $profile::analytics::refinery::path

    # Shortcut var to DRY up commands.
    $env = "export PYTHONPATH=\${PYTHONPATH}:${refinery_path}/python"
    $systemd_env = {
        'PYTHONPATH' => "\${PYTHONPATH}:${refinery_path}/python",
    }

    # Send an email to analytics in case of failure
    $mail_to = 'analytics-alerts@wikimedia.org'

    # Keep this many days of raw webrequest data.
    $raw_retention_days = 31
    kerberos::systemd_timer { 'refinery-drop-webrequest-raw-partitions':
        description  => 'Drop Webrequest raw data imported on HDFS following data retention policies.',
        command      => "${refinery_path}/bin/refinery-drop-older-than --database='wmf_raw' --tables='webrequest' --base-path='/wmf/data/raw/webrequest' --path-format='.+/hourly/(?P<year>[0-9]+)(/(?P<month>[0-9]+)(/(?P<day>[0-9]+)(/(?P<hour>[0-9]+))?)?)?' --older-than='${raw_retention_days}' --skip-trash --execute='96726ec893174544fc9bd7c7fa0083ea'",
        interval     => '*-*-* 00/4:15:00',
        environment  => $systemd_env,
        user         => 'analytics',
        use_kerberos => $use_kerberos,
    }

    # Keep this many days of refined webrequest data.
    $refined_retention_days = 90
    kerberos::systemd_timer { 'refinery-drop-webrequest-refined-partitions':
        description  => 'Drop Webrequest refined data imported on HDFS following data retention policies.',
        command      => "${refinery_path}/bin/refinery-drop-older-than --database='wmf' --tables='webrequest' --base-path='/wmf/data/wmf/webrequest' --path-format='.+/year=(?P<year>[0-9]+)(/month=(?P<month>[0-9]+)(/day=(?P<day>[0-9]+)(/hour=(?P<hour>[0-9]+))?)?)?' --older-than='${refined_retention_days}' --skip-trash --execute='cf16215b8158e765b623db7b3f345d36'",
        interval     => '*-*-* 00/4:45:00',
        environment  => $systemd_env,
        user         => 'analytics',
        use_kerberos => $use_kerberos,
    }

    # keep this many days of druid webrequest sampled
    # Currently being tested as systemd timer, see below
    $druid_webrequest_sampled_retention_days = 60
    kerberos::systemd_timer { 'refinery-drop-webrequest-sampled-druid':
        description  => 'Drop Druid Webrequest sampled data from deep storage following data retention policies.',
        command      => "${refinery_path}/bin/refinery-drop-druid-deep-storage-data --druid-host analytics1041.eqiad.wmnet -d ${druid_webrequest_sampled_retention_days} webrequest_sampled_128",
        interval     => '*-*-* 05:15:00',
        environment  => $systemd_env,
        use_kerberos => $use_kerberos,
        user         => 'analytics',
    }
}
