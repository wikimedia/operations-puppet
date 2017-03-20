# == Class role::analytics_cluster::refinery::job::sqoop_mediawiki
# Schedules sqoop to import MediaWiki databases into Hadoop monthly.
# NOTE: This requires that role::analytics_cluster::mysql_password has
# been included somewhere, so that /user/hdfs/mysql-analytics-research-client-pw.txt
# exists in HDFS.  (We can't require it here, since it needs to only be included once
# on a different node.)
#
class role::analytics_cluster::refinery::job::sqoop_mediawiki {
    require ::role::analytics_cluster::refinery

    # Shortcut var to DRY up cron commands.
    $env = "export PYTHONPATH=\${PYTHONPATH}:${role::analytics_cluster::refinery::path}/python"

    $output_directory = '/wmf/data/raw/mediawiki/tables'
    $wiki_file        = '/mnt/hdfs/wmf/refinery/current/static_data/mediawiki/grouped_wikis/labs_grouped_wikis.csv'
    # We regularly sqoop out of labsdb so that data is pre-sanitized.
    $db_host          = 'labsdb-analytics.eqiad.wmnet'
    $db_user          = 'research'
    $db_password_file = '/user/hdfs/mysql-analytics-research-client-pw.txt'

    cron { 'refinery-sqoop-mediawiki':
        command => "${env} && /usr/bin/python3 ${role::analytics_cluster::refinery::path}/bin/sqoop-mediawiki-tables --job-name sqoop-mediawiki-monthly-$(/bin/date '+%Y-%m') --labsdb --jdbc-host ${db_host} --output-dir ${$output_directory} --wiki-file  ${wiki_file} --user ${db_user} --password-file ${db_password_file} --timestamp \$(/bin/date '+%Y%m01000000') --snapshot \$(/bin/date '+%Y-%m')"
        user    => 'hdfs',
        minute  => '0',
        hour    => '0'
        # Start on the fifth day of every month.
        day     => '5'
    }
}
