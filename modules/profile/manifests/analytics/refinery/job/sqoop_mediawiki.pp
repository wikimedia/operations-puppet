# == Class profile::analytics::refinery::job::sqoop_mediawiki
# Schedules sqoop to import MediaWiki databases into Hadoop monthly and daily.
# NOTE: This requires that role::analytics_cluster::mysql_password has
# been included somewhere, so that /user/hdfs/mysql-analytics-research-client-pw.txt
# exists in HDFS.  (We can't require it here, since it needs to only be included once
# on a different node.) 
#
class profile::analytics::refinery::job::sqoop_mediawiki (
    Wmflib::Ensure $ensure_timers = lookup('profile::analytics::refinery::job::sqoop_mediawiki::ensure_timers', { 'default_value' => 'present' }),
){
    require ::profile::analytics::refinery

    include ::passwords::mysql::analytics_labsdb
    include ::passwords::mysql::research

    $refinery_path              = $profile::analytics::refinery::path

    # Shortcut var to DRY up cron commands.
    $env = "export PYTHONPATH=\${PYTHONPATH}:${refinery_path}/python"

    $output_directory_labs      = '/wmf/data/raw/mediawiki/tables'
    $output_directory_private   = '/wmf/data/raw/mediawiki_private/tables'
    $wiki_file                  = '/mnt/hdfs/wmf/refinery/current/static_data/mediawiki/grouped_wikis/grouped_wikis.csv'
    # We sqoop most tables out of clouddb so that data is pre-sanitized.
    $labs_db_user               = $::passwords::mysql::analytics_labsdb::user
    $labs_log_file              = "${::profile::analytics::refinery::log_dir}/sqoop-mediawiki.log"
    # Sqoop anything private out of analytics-store
    $private_db_user            = $::passwords::mysql::research::user
    $private_log_file           = "${::profile::analytics::refinery::log_dir}/sqoop-mediawiki-private.log"
    # Separate logs for sqoops from production replicas
    $production_log_file        = "${::profile::analytics::refinery::log_dir}/sqoop-mediawiki-production.log"
    $production_daily_log_file  = "${::profile::analytics::refinery::log_dir}/sqoop-mediawiki-production-daily.log"
    # These are rendered elsewhere by role::analytics_cluster::mysql_password.
    $db_password_labs           = '/user/analytics/mysql-analytics-labsdb-client-pw.txt'
    $db_password_private        = '/user/analytics/mysql-analytics-research-client-pw.txt'
    # number of parallel processors to use when sqooping (querying MySQL)
    $num_processors             = 10
    # number of sqoop mappers to use for jobs getting data
    # since the beginning of wiki times or since 1 month
    $num_mappers_all_times      = 64
    $num_mappers_one_month      = 4
    # Yarn queue to run sqoop jobs in: production
    $yarn_queue                 = 'production'

    ############################################################################
    # Template uses num_mappers_all_times

    # sqoop tables needed by the mediawiki history data pipeline, from cloud replicas
    file { '/usr/local/bin/refinery-sqoop-mediawiki-history':
        ensure  => $ensure_timers,
        content => template('profile/analytics/refinery/job/refinery-sqoop-mediawiki-history.sh.erb'),
        mode    => '0550',
        owner   => 'analytics',
        group   => 'analytics',
    }

    # sqoop tables not needed by the mediawiki history data pipeline, from cloud replicas
    file { '/usr/local/bin/refinery-sqoop-mediawiki-not-history':
        ensure  => $ensure_timers,
        content => template('profile/analytics/refinery/job/refinery-sqoop-mediawiki-not-history.sh.erb'),
        mode    => '0550',
        owner   => 'analytics',
        group   => 'analytics',
    }

    # sqoop from analytics-store replicas, tables not available on cloud replicas for privacy reasons
    file { '/usr/local/bin/refinery-sqoop-mediawiki-production':
        ensure  => $ensure_timers,
        content => template('profile/analytics/refinery/job/refinery-sqoop-mediawiki-production.sh.erb'),
        mode    => '0550',
        owner   => 'analytics',
        group   => 'analytics',
    }

    file { '/usr/local/bin/refinery-sqoop-whole-mediawiki':
        ensure  => $ensure_timers,
        content => template('profile/analytics/refinery/job/refinery-sqoop-whole-mediawiki.sh.erb'),
        mode    => '0550',
        owner   => 'analytics',
        group   => 'analytics',
        require => File['/usr/local/bin/refinery-sqoop-mediawiki', '/usr/local/bin/refinery-sqoop-mediawiki-production'],
    }

    # Used to store sqoop-generated jar that is rebuilt at each script run
    file { '/tmp/sqoop-jars':
        ensure => directory,
        mode   => '0755',
        owner  => 'analytics',
        group  => 'analytics',
    }

    kerberos::systemd_timer { 'refinery-sqoop-whole-mediawiki':
        ensure      => $ensure_timers,
        description => 'Schedules sqoop to import whole MediaWiki databases into Hadoop monthly.',
        command     => '/usr/local/bin/refinery-sqoop-whole-mediawiki',
        interval    => '*-*-01 00:00:00',
        user        => 'analytics',
        require     => [File['/usr/local/bin/refinery-sqoop-whole-mediawiki'], File['/tmp/sqoop-jars']],
    }

    ############################################################################
    # 1 month of tables from analytics-store, expected to last less than 2 hours
    # Template uses num_mappers_one_month
    # Tables: cu_changes

    file { '/usr/local/bin/refinery-sqoop-mediawiki-private':
        ensure  => $ensure_timers,
        content => template('profile/analytics/refinery/job/refinery-sqoop-mediawiki-private.sh.erb'),
        mode    => '0550',
        owner   => 'analytics',
        group   => 'analytics',
    }

    kerberos::systemd_timer { 'refinery-sqoop-mediawiki-private':
        ensure      => $ensure_timers,
        description => 'Schedules sqoop to import MediaWiki databases (containing PII data) into Hadoop monthly.',
        command     => '/usr/local/bin/refinery-sqoop-mediawiki-private',
        interval    => '*-*-02 00:00:00',
        user        => 'analytics',
        require     => [File['/usr/local/bin/refinery-sqoop-mediawiki-private'], File['/tmp/sqoop-jars']],
    }

    ############################################################################
    # daily sqoop of all data in some small tables.  Expected to last an hour or
    # two on most runs and not use up too many resources.
    # Template uses num_mappers_one_month
    # Tables: discussiontools_subscription

    file { '/usr/local/bin/refinery-sqoop-mediawiki-production-daily':
        ensure  => $ensure_timers,
        content => template('profile/analytics/refinery/job/refinery-sqoop-mediawiki-production-daily.sh.erb'),
        mode    => '0550',
        owner   => 'analytics',
        group   => 'analytics',
    }

    kerberos::systemd_timer { 'refinery-sqoop-mediawiki-production-daily':
        ensure      => $ensure_timers,
        description => 'Schedules sqoop to import one-off MediaWiki tables into Hadoop daily.',
        command     => '/usr/local/bin/refinery-sqoop-mediawiki-production-daily',
        interval    => '*-*-* 05:00:00',
        user        => 'analytics',
        require     => [File['/tmp/sqoop-jars']],
    }
}
