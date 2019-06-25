# == Class profile::analytics::search::jobs
#
# Installs Analytics-related systemd-timer jobs
# for the Search team.
#
class profile::analytics::search::jobs (
    $use_kerberos = lookup('profile::analytics::search::jobs::use_kerberos', { 'default_value' => false }),
) {
    require ::profile::analytics::refinery

    # Shortcut to refinery path
    $refinery_path = $profile::analytics::refinery::path

    $systemd_env = {
        'PYTHONPATH' => "\${PYTHONPATH}:${refinery_path}/python",
    }

    file { '/var/log/analytics-search':
        ensure => 'directory',
        owner  => 'root',
        group  => 'analytics-search',
        mode   => '0775',
    }

    logrotate::rule { 'analytics-search-logs':
        ensure       => present,
        file_glob    => '/var/log/analytics-search/*.log',
        frequency    => 'daily',
        rotate       => 10,
        missing_ok   => true,
        not_if_empty => true,
        no_create    => true,
        su           => 'root analytics-search',
    }

    # keep this many days of search query click files
    # runs once a day
    $query_clicks_retention_days = 90
    $query_clicks_log_file = '/var/log/analytics-search/drop-query-clicks.log'

    kerberos::systemd_timer { 'search-drop-query-clicks':
        description               => 'Drop cirrus click logs from Hive/HDFS following data retention policies.',
        command                   => "${refinery_path}/bin/refinery-drop-hive-partitions -d ${query_clicks_retention_days} -D discovery -t query_clicks_hourly,query_clicks_daily -f ${query_clicks_log_file}",
        monitoring_contact_groups => 'team-discovery',
        environment               => $systemd_env,
        interval                  => '*-*-* 03:30:00',
        user                      => 'analytics-search',
        use_kerberos              => $use_kerberos,
    }
}
