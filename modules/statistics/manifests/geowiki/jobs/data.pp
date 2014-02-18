# Installs a cron job to get recent editor data
# from the research slave databases and generate
# editor geocoding statistics, saved back into a db.
#
class statistics::geowiki::jobs::data {
    require statistics::geowiki,
        statistics::geowiki::mysql,
        passwords::mysql::globaldev,
        statistics::packages,
        geoip

    $geowiki_user                     = $statistics::geowiki::geowiki_user
    $geowiki_base_path                = $statistics::geowiki::geowiki_base_path
    $geowiki_scripts_path             = $statistics::geowiki::geowiki_scripts_path

    $geowiki_mysql_research_conf_file = $statistics::geowiki::mysql::conf_file

    # install MySQL conf files for db acccess
    $globaldev_mysql_user = $passwords::mysql::globaldev::user
    $globaldev_mysql_pass = $passwords::mysql::globaldev::pass

    $geowiki_mysql_globaldev_conf_file = "${geowiki_base_path}/.globaldev.my.cnf"
    file { $geowiki_mysql_globaldev_conf_file:
        owner   => $geowiki_user,
        group   => $geowiki_user,
        mode    => '0400',
        content => "
[client]
user=${globaldev_mysql_user}
password=${globaldev_mysql_pass}
",
    }

    $geowiki_log_path = "${geowiki_base_path}/logs"
    file { $geowiki_log_path:
        ensure  => 'directory',
        owner   => $geowiki_user,
        group   => $geowiki_user,
    }

    # cron to run geowiki/process_data.py.
    # This will query the production slaves and
    # store results in the research staging database.
    # Logs will be kept $geowiki_log_path.
    cron { 'geowiki-process-data':
        minute  => 0,
        hour    => 12,
        user    => $geowiki_user,
        command => "/usr/bin/python ${geowiki_scripts_path}/geowiki/process_data.py -o ${$geowiki_log_path} --wpfiles ${geowiki_scripts_path}/geowiki/data/all_ids.tsv --daily --start=`date --date='-2 day' +\\%Y-\\%m-\\%d` --end=`date --date='0 day' +\\%Y-\\%m-\\%d` --source_sql_cnf=${geowiki_mysql_globaldev_conf_file} --dest_sql_cnf=${geowiki_mysql_research_conf_file} >${geowiki_log_path}/process_data.py-cron-`date >+\\%Y-\\%m-\\%d--\\%H-\\%M-\\%S`.stdout >2>${geowiki_log_path}/process_data.py-cron-`date  >+\\%Y-\\%m-\\%d--\\%H-\\%M-\\%S`.stderr",
        require => File[$geowiki_log_path],
    }
}

