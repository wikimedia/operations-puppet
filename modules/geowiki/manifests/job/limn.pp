# == Class geowiki::job::limn
# Installs a cron job to create limn files from the geocoded editor data.
#
class geowiki::job::limn {
    require ::geowiki::job
    require ::geowiki::private_data

    # cron job to do the actual fetching from the database, computation of
    # the limn files, and pushing the limn files to the data repositories
    cron { 'geowiki-process-db-to-limn':
        minute      => 0,
        hour        => 15,
        user        => $::geowiki::user,
        environment => 'MAILTO=analytics-alerts@wikimedia.org',
        command     => "${::geowiki::scripts_path}/scripts/make_and_push_limn_files.sh --cron-mode --basedir_private=${::geowiki::private_data_path} --source_sql_cnf=${::geowiki::mysql_conf::conf_file}",
        require     => [
            Git::Clone['geowiki-scripts'],
            Git::Clone['geowiki-data-private'],
            File[$::geowiki::mysql_conf::conf_file],
        ],
    }
}
