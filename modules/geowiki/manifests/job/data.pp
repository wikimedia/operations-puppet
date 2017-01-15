# == Class geowiki::job::data
# Installs a cron job to get recent editor data
# from the research slave databases and generate
# editor geocoding statistics, saved back into a db.
#
class geowiki::job::data inherits geowiki::job {
    include ::passwords::mysql::globaldev

    # install MySQL conf files for db acccess
    $globaldev_mysql_user = $passwords::mysql::globaldev::user
    $globaldev_mysql_pass = $passwords::mysql::globaldev::pass

    $geowiki_mysql_globaldev_conf_file = "${::geowiki::params::path}/.globaldev.my.cnf"
    file { $geowiki_mysql_globaldev_conf_file:
        owner   => $::geowiki::params::user,
        group   => $::geowiki::params::user,
        mode    => '0400',
        content => "
[client]
user=${globaldev_mysql_user}
password=${globaldev_mysql_pass}
",
    }

    # cron to run geowiki/process_data.py.
    # This will query the production slaves and
    # store results in the research staging database.
    # Logs will be kept $geowiki_log_path.
    cron { 'geowiki-process-data':
        minute  => 0,
        hour    => 12,
        user    => $::geowiki::params::user,
        command => "/usr/bin/python ${::geowiki::params::scripts_path}/geowiki/process_data.py -o ${::geowiki::params::log_path} --wpfiles ${::geowiki::params::scripts_path}/geowiki/data/all_ids.tsv --daily --start=`date --date='-2 day' +\\%Y-\\%m-\\%d` --end=`date --date='0 day' +\\%Y-\\%m-\\%d` --source_sql_cnf=${geowiki_mysql_globaldev_conf_file} --dest_sql_cnf=${::geowiki::mysql_conf::conf_file} >${::geowiki::params::log_path}/process_data.py-cron-`date +\\%Y-\\%m-\\%d--\\%H-\\%M-\\%S`.stdout 2>${::geowiki::params::log_path}/process_data.py-cron-`date +\\%Y-\\%m-\\%d--\\%H-\\%M-\\%S`.stderr",
        require => File[$::geowiki::params::log_path],
    }
}
