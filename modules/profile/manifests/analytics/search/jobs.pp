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
        command                   => "${refinery_path}/bin/refinery-drop-older-than --database='discovery' --tables='query_clicks_(hourly|daily)' --base-path='/wmf/data/discovery/query_clicks' --path-format='(daily|hourly)/year=(?P<year>[0-9]+)(/month=(?P<month>[0-9]+)(/day=(?P<day>[0-9]+)(/hour=(?P<hour>[0-9]+))?)?)?' --older-than='${query_clicks_retention_days}' --skip-trash --execute='417dcd3df9c5c457f9da7f95e2685041' --log-file ${query_clicks_log_file}",
        monitoring_contact_groups => 'team-discovery',
        environment               => $systemd_env,
        interval                  => '*-*-* 03:30:00',
        user                      => 'analytics-search',
        use_kerberos              => $use_kerberos,
    }
}
