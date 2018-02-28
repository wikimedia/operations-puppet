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

    # Shortcut var to DRY up cron commands.
    $env = "export PYTHONPATH=\${PYTHONPATH}:${profile::analytics::refinery::path}/python"

    $output_directory_labs      = '/wmf/data/raw/mediawiki/tables'
    $output_directory_private   = '/wmf/data/raw/mediawiki_private/tables'
    $wiki_file_labs             = '/mnt/hdfs/wmf/refinery/current/static_data/mediawiki/grouped_wikis/labs_grouped_wikis.csv'
    $wiki_file_private          = '/mnt/hdfs/wmf/refinery/current/static_data/mediawiki/grouped_wikis/prod_grouped_wikis.csv'
    # We sqoop most tables out of labsdb so that data is pre-sanitized.
    $labs_db_host               = 'labsdb-analytics.eqiad.wmnet'
    $labs_db_user               = $::passwords::mysql::analytics_labsdb::user
    $labs_log_file              = "${::profile::analytics::refinery::log_dir}/sqoop-mediawiki.log"
    # Sqoop anything private out of analytics-store
    $private_db_host            = 'analytics-store.eqiad.wmnet'
    $private_db_user            = $::passwords::mysql::research::user
    $private_log_file           = "${::profile::analytics::refinery::log_dir}/sqoop-mediawiki-private.log"
    # These are rendered elsewhere by role::analytics_cluster::mysql_password.
    $db_password_labs           = '/user/hdfs/mysql-analytics-labsdb-client-pw.txt'
    $db_password_private        = '/user/hdfs/mysql-analytics-research-client-pw.txt'
    # number of parallel processors to use when sqooping (querying MySQL)
    $num_processors             = 3
    # number of sqoop mappers to use, but only for tables on big wiki
    $num_mappers                = 4
    # pre-compiled set of java classes for sqoop's convenience
    $orm_jar_file               = "${::profile::analytics::refinery::path}/artifacts/mediawiki-tables-sqoop-orm.jar"

    cron { 'refinery-sqoop-mediawiki':
        command  => "${env} && /usr/bin/python3 ${profile::analytics::refinery::path}/bin/sqoop-mediawiki-tables --job-name sqoop-mediawiki-monthly-$(/bin/date --date=\"$(/bin/date +\\%Y-\\%m-15) -1 month\" +'\\%Y-\\%m') --labsdb --jdbc-host ${labs_db_host} --output-dir ${$output_directory_labs} --wiki-file  ${wiki_file_labs} --tables archive,ipblocks,logging,page,pagelinks,redirect,revision,user,user_groups --jar-file ${orm_jar_file} --user ${labs_db_user} --password-file ${db_password_labs} --from-timestamp 20010101000000 --to-timestamp \$(/bin/date '+\\%Y\\%m01000000') --partition-name snapshot --partition-value \$(/bin/date --date=\"$(/bin/date +\\%Y-\\%m-15) -1 month\" +'\\%Y-\\%m') --mappers ${num_mappers} --processors ${num_processors} --log-file ${labs_log_file}",
        user     => 'hdfs',
        minute   => '0',
        hour     => '0',
        # Start on the second day of every month.
        monthday => '2',
    }

    cron { 'refinery-sqoop-mediawiki-private':
        command  => "${env} && /usr/bin/python3 ${profile::analytics::refinery::path}/bin/sqoop-mediawiki-tables --job-name sqoop-mediawiki-monthly-$(/bin/date --date=\"$(/bin/date +\\%Y-\\%m-15) -1 month\" +'\\%Y-\\%m') --jdbc-host ${private_db_host} --output-dir ${$output_directory_private} --wiki-file  ${wiki_file_private} --tables cu_changes --jar-file ${orm_jar_file} --user ${private_db_user} --password-file ${db_password_private} --from-timestamp \$(/bin/date --date=\"$(/bin/date +\\%Y-\\%m-15) -1 month\" +'\\%Y\\%m01000000') --to-timestamp \$(/bin/date '+\\%Y\\%m01000000') --partition-name month --partition-value \$(/bin/date --date=\"$(/bin/date +\\%Y-\\%m-15) -1 month\" +'\\%Y-\\%m') --mappers ${num_mappers} --processors ${num_processors} --log-file ${private_log_file}",
        user     => 'hdfs',
        minute   => '0',
        hour     => '0',
        # Start on the second day of every month.
        monthday => '2',
    }
}

