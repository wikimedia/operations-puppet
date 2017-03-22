# == Class role::analytics_cluster::refinery::job::sqoop_mediawiki
# Schedules sqoop to import MediaWiki databases into Hadoop monthly.
# NOTE: This requires that role::analytics_cluster::mysql_password has
# been included somewhere, so that /user/hdfs/mysql-analytics-research-client-pw.txt
# exists in HDFS.  (We can't require it here, since it needs to only be included once
# on a different node.)
#
class role::analytics_cluster::refinery::job::sqoop_mediawiki {
    require ::role::analytics_cluster::refinery

    include ::passwords::mysql::analytics_labsdb

    # Shortcut var to DRY up cron commands.
    $env = "export PYTHONPATH=\${PYTHONPATH}:${role::analytics_cluster::refinery::path}/python"

    $output_directory = '/wmf/data/raw/mediawiki/tables'
    $wiki_file        = '/mnt/hdfs/wmf/refinery/current/static_data/mediawiki/grouped_wikis/labs_grouped_wikis.csv'
    # We regularly sqoop out of labsdb so that data is pre-sanitized.
    $db_host          = 'labsdb-analytics.eqiad.wmnet'
    $db_user          = $::passwords::mysql::analytics_labsdb::user
    # This is rendered elsewhere by role::analytics_cluster::mysql_password.
    $db_password_file = '/user/hdfs/mysql-analytics-labsdb-client-pw.txt'
    $log_file         = "${::role::analytics_cluster::refinery::log_dir}/sqoop-mediawiki.log"

    cron { 'refinery-sqoop-mediawiki':
        command  => "${env} && /usr/bin/python3 ${role::analytics_cluster::refinery::path}/bin/sqoop-mediawiki-tables --job-name sqoop-mediawiki-monthly-$(/bin/date '+%Y-%m') --labs --jdbc-host ${db_host} --output-dir ${$output_directory} --wiki-file  ${wiki_file} --user ${db_user} --password-file ${db_password_file} --timestamp \$(/bin/date '+%Y%m01000000') --snapshot \$(/bin/date '+%Y-%m') >> ${log_file} 2>&1",
        user     => 'hdfs',
        minute   => '0',
        hour     => '0',
        # Start on the second day of every month.
        monthday => '2',
    }
}
