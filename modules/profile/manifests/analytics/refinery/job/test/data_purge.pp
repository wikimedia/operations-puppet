    # == Class profile::analytics::refinery::job::test::data_purge
#
# Installs systemd timers to drop old hive partitions,
# delete old data from HDFS (Testing cluster)
#
class profile::analytics::refinery::job::test::data_purge(
    Wmflib::Ensure $ensure_timers       = lookup('profile::analytics::refinery::job:test:data_purge::ensure_timers', { 'default_value' => 'present' }),
) {
    require ::profile::analytics::refinery

    # Shortcut to refinery path
    $refinery_path = $profile::analytics::refinery::path

    $systemd_env = {
        'PYTHONPATH' => "\${PYTHONPATH}:${refinery_path}/python",
    }

    # Conventional Hive format path with partition keys (used by Gobblin), i.e. year=yyyy/month=mm/day=dd/hour=hh.
    $hive_date_path_format = 'year=(?P<year>[0-9]+)(/month=(?P<month>[0-9]+)(/day=(?P<day>[0-9]+)(/hour=(?P<hour>[0-9]+))?)?)?'

    # Most jobs will use this retention_days period.
    $retention_days = 90

    # Keep this many days of raw webrequest data.
    $webrequest_raw_retention_days = 31
    kerberos::systemd_timer { 'refinery-drop-webrequest-raw-partitions':
        ensure      => $ensure_timers,
        description => 'Drop Webrequest raw (/wmf/data/raw/webrequset) data imported on HDFS following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --database='wmf_raw' --tables='webrequest' --base-path='/wmf/data/raw/webrequest' --path-format='.+/${hive_date_path_format}' --older-than='${webrequest_raw_retention_days}' --allowed-interval='3' --skip-trash --execute='1174bbc96c9b1cee08bc20b3544b1c7f'",
        interval    => '*-*-* 00/4:15:00',
        environment => $systemd_env,
        user        => 'analytics',
    }

    kerberos::systemd_timer { 'refinery-drop-webrequest-refined-partitions':
        ensure      => $ensure_timers,
        description => 'Drop Webrequest refined (/wmf/data/wmf/webrequest) data imported on HDFS following data retention policies.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --database='wmf' --tables='webrequest' --base-path='/wmf/data/wmf/webrequest' --path-format='.+/${hive_date_path_format}' --older-than='${retention_days}' --allowed-interval='3' --skip-trash --execute='7fda1bf5f04e6883293a6b4a019b3b02'",
        interval    => '*-*-* 00/4:45:00',
        environment => $systemd_env,
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

    # Drop old data from all tables in the Hive event database with tables in /wmf/data/event.
    # Data that should be kept indefinitely is sanitized by refine_sanitize jobs into the
    # event_sanitized Hive database, so all data older than 90 days should be safe to drop.
    $drop_event_log_file = "${profile::analytics::refinery::log_dir}/drop_event.log"
    kerberos::systemd_timer { 'drop_event':
        ensure      => $ensure_timers,
        description => 'Drop data in Hive event database older than 90 days.',
        command     => "${refinery_path}/bin/refinery-drop-older-than --database='event' --tables='.*' --base-path='/wmf/data/event' --path-format='[^/]+(/datacenter=[^/]+)?/year=(?P<year>[0-9]+)(/month=(?P<month>[0-9]+)(/day=(?P<day>[0-9]+)(/hour=(?P<hour>[0-9]+))?)?)?' --older-than='${retention_days}' --allowed-interval='3' --execute='0586baac1a9b1439fd361f9aae8af698' --log-file='${drop_event_log_file}'",
        interval    => '*-*-* 00:00:00',
        environment => $systemd_env,
        user        => 'analytics',
    }
}
