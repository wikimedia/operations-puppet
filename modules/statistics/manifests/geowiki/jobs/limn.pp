# == Class statistics::geowiki::jobs::limn
# Installs a cron job to create limn files from the geocoded editor data.
class statistics::geowiki::jobs::limn {
    require statistics::geowiki,
        statistics::geowiki::mysql,
        statistics::geowiki::data::private,
        statistics::packages

    $geowiki_user                     = $statistics::geowiki::geowiki_user
    $geowiki_base_path                = $statistics::geowiki::geowiki_base_path
    $geowiki_scripts_path             = $statistics::geowiki::geowiki_scripts_path
    $geowiki_public_data_path         = "${geowiki_base_path}/data-public"
    $geowiki_private_data_path        = $statistics::geowiki::data::private::geowiki_private_data_path
    $geowiki_mysql_research_conf_file = $statistics::geowiki::mysql::conf_file

    git::clone { 'geowiki-data-public':
        ensure    => 'latest',
        directory => $geowiki_public_data_path,
        origin    => 'ssh://gerrit.wikimedia.org:29418/analytics/geowiki/data-public.git',
        owner     => $geowiki_user,
        group     => $geowiki_user,
    }

    # cron job to do the actual fetching from the database, computation of
    # the limn files, and pushing the limn files to the data repositories
    cron { 'geowiki-process-db-to-limn':
        minute  => 0,
        hour    => 15,
        user    => $geowiki_user,
        command => "${geowiki_scripts_path}/scripts/make_and_push_limn_files.sh --cron-mode --basedir_public=${geowiki_public_data_path} --basedir_private=${geowiki_private_data_path} --source_sql_cnf=${geowiki_mysql_research_conf_file}",
        require => [
            Git::Clone['geowiki-scripts'],
            Git::Clone['geowiki-data-public'],
            Git::Clone['geowiki-data-private'],
            File[$geowiki_mysql_research_conf_file],
        ],
    }
}

