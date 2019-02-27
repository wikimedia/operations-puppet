# == Class profile::analytics::refinery::job::sqoop_mediawiki
# Schedules sqoop to import MediaWiki databases into Hadoop monthly.
# NOTE: This requires that role::analytics_cluster::mysql_password has
# been included somewhere, so that /user/hdfs/mysql-analytics-research-client-pw.txt
# exists in HDFS.  (We can't require it here, since it needs to only be included once
# on a different node.)
#
class profile::analytics::refinery::job::sqoop_mediawiki {
    require ::profile::analytics::refinery

    include ::passwords::mysql::analytics_labsdb
    include ::passwords::mysql::research

    $refinery_path              = $profile::analytics::refinery::path

    # Shortcut var to DRY up cron commands.
    $env = "export PYTHONPATH=\${PYTHONPATH}:${refinery_path}/python"

    $output_directory_labs      = '/wmf/data/raw/mediawiki/tables'
    $output_directory_private   = '/wmf/data/raw/mediawiki_private/tables'
    $wiki_file_labs             = '/mnt/hdfs/wmf/refinery/current/static_data/mediawiki/grouped_wikis/labs_grouped_wikis.csv'
    $wiki_file_private          = '/mnt/hdfs/wmf/refinery/current/static_data/mediawiki/grouped_wikis/prod_grouped_wikis.csv'
    # We sqoop most tables out of labsdb so that data is pre-sanitized.
    $labs_db_user               = $::passwords::mysql::analytics_labsdb::user
    $labs_log_file              = "${::profile::analytics::refinery::log_dir}/sqoop-mediawiki.log"
    # Sqoop anything private out of analytics-store
    $private_db_user            = $::passwords::mysql::research::user
    $private_log_file           = "${::profile::analytics::refinery::log_dir}/sqoop-mediawiki-private.log"
    # Separate log for sqoops from production replicas
    $production_log_file        = "${::profile::analytics::refinery::log_dir}/sqoop-mediawiki-production.log"
    # These are rendered elsewhere by role::analytics_cluster::mysql_password.
    $db_password_labs           = '/user/hdfs/mysql-analytics-labsdb-client-pw.txt'
    $db_password_private        = '/user/hdfs/mysql-analytics-research-client-pw.txt'
    # number of parallel processors to use when sqooping (querying MySQL)
    $num_processors             = 3
    # number of sqoop mappers to use, but only for tables on big wiki
    $num_mappers                = 4

    file { '/usr/local/bin/refinery-sqoop-mediawiki':
        content => template('profile/analytics/refinery/job/refinery-sqoop-mediawiki.sh.erb'),
        mode    => '0550',
        owner   => 'hdfs',
        group   => 'hdfs',
    }

    profile::analytics::systemd_timer { 'refinery-sqoop-mediawiki':
        description => 'Schedules sqoop to import MediaWiki databases into Hadoop monthly.',
        command     => '/usr/local/bin/refinery-sqoop-mediawiki',
        interval    => '*-*-05 00:00:00',
        user        => 'hdfs',
        require     => File['/usr/local/bin/refinery-sqoop-mediawiki'],
    }

    file { '/usr/local/bin/refinery-sqoop-mediawiki-production':
        content => template('profile/analytics/refinery/job/refinery-sqoop-mediawiki-production.sh.erb'),
        mode    => '0550',
        owner   => 'hdfs',
        group   => 'hdfs',
    }

    profile::analytics::systemd_timer { 'refinery-sqoop-mediawiki-production':
        description => 'Schedules sqoop to import MediaWiki databases from prod replicas into Hadoop monthly.',
        command     => '/usr/local/bin/refinery-sqoop-mediawiki-production',
        interval    => '*-*-07 00:00:00',
        user        => 'hdfs',
        require     => File['/usr/local/bin/refinery-sqoop-mediawiki-production'],
    }

    file { '/usr/local/bin/refinery-sqoop-mediawiki-private':
        content => template('profile/analytics/refinery/job/refinery-sqoop-mediawiki-private.sh.erb'),
        mode    => '0550',
        owner   => 'hdfs',
        group   => 'hdfs',
    }

    profile::analytics::systemd_timer { 'refinery-sqoop-mediawiki-private':
        description => 'Schedules sqoop to import MediaWiki databases (containing PII data) into Hadoop monthly.',
        command     => '/usr/local/bin/refinery-sqoop-mediawiki-private',
        interval    => '*-*-02 00:00:00',
        user        => 'hdfs',
        require     => File['/usr/local/bin/refinery-sqoop-mediawiki-private'],
    }
}

