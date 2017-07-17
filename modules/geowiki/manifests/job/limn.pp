# == Class geowiki::job::limn
# Installs a cron job to create limn files from the geocoded editor data.
#
class geowiki::job::limn {
    require ::geowiki::job
    require ::geowiki::private_data

    git::clone { 'geowiki-data-public':
        ensure    => 'latest',
        directory => $::geowiki::public_data_path,
        origin    => "https://${::geowiki::user}@gerrit.wikimedia.org/r/a/analytics/geowiki/data-public",
        owner     => $::geowiki::user,
        group     => $::geowiki::user,
    }

    # cron job to do the actual fetching from the database, computation of
    # the limn files, and pushing the limn files to the data repositories
    cron { 'geowiki-process-db-to-limn':
        minute  => 0,
        hour    => 15,
        user    => $::geowiki::user,
        command => "${::geowiki::scripts_path}/scripts/make_and_push_limn_files.sh --cron-mode --basedir_public=${::geowiki::public_data_path} --basedir_private=${::geowiki::private_data_path} --source_sql_cnf=${::geowiki::mysql_conf::conf_file}",
        require => [
            Git::Clone['geowiki-scripts'],
            Git::Clone['geowiki-data-public'],
            Git::Clone['geowiki-data-private'],
            File[$::geowiki::mysql_conf::conf_file],
        ],
    }
}
