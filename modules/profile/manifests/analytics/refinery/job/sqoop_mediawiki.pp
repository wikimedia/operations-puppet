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

    cron { 'refinery-sqoop-mediawiki':
        command     => "${env} && /usr/bin/python3 ${profile::analytics::refinery::path}/bin/sqoop-mediawiki-tables -j sqoop-mediawiki-monthly-$(/bin/date --date=\"$(/bin/date +\\%Y-\\%m-15) -1 month\" +'\\%Y-\\%m') -l -H ${labs_db_host} -d ${$output_directory_labs} -w ${wiki_file_labs} -t archive,ipblocks,logging,page,pagelinks,redirect,revision,user,user_groups -u ${labs_db_user} -p ${db_password_labs} -F 20010101000000 -T \$(/bin/date '+\\%Y\\%m01000000') -s snapshot -x \$(/bin/date --date=\"$(/bin/date +\\%Y-\\%m-15) -1 month\" +'\\%Y-\\%m') -m ${num_mappers} -a avrodata -k ${num_processors} -o ${labs_log_file}",
        user        => 'hdfs',
        minute      => '0',
        hour        => '0',
        # Start on the fifth day of every month.
        monthday    => '5',
        environment => 'MAILTO=analytics-alerts@wikimedia.org',
    }

    cron { 'refinery-sqoop-mediawiki-private':
        command     => "${env} && /usr/bin/python3 ${profile::analytics::refinery::path}/bin/sqoop-mediawiki-tables -j sqoop-mediawiki-monthly-private-$(/bin/date --date=\"$(/bin/date +\\%Y-\\%m-15) -1 month\" +'\\%Y-\\%m') -H ${private_db_host} -d ${$output_directory_private} -w ${wiki_file_private} -t cu_changes -u ${private_db_user} -p ${db_password_private} -F \$(/bin/date --date=\"$(/bin/date +\\%Y-\\%m-15) -1 month\" +'\\%Y\\%m01000000') -T \$(/bin/date '+\\%Y\\%m01000000') -s month -x \$(/bin/date --date=\"$(/bin/date +\\%Y-\\%m-15) -1 month\" +'\\%Y-\\%m') -m ${num_mappers} -a avrodata -k ${num_processors} -o ${private_log_file}",
        user        => 'hdfs',
        minute      => '0',
        hour        => '0',
        # Start on the second day of every month.
        monthday    => '2',
        environment => 'MAILTO=analytics-alerts@wikimedia.org',
    }
}

