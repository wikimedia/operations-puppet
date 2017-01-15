# == Class geowiki::job::limn
# Installs a cron job to create limn files from the geocoded editor data.
#
class geowiki::job::limn inherits geowiki::job {
    require ::geowiki::private_data

    git::clone { 'geowiki-data-public':
        ensure    => 'latest',
        directory => $::geowiki::params::public_data_path,
        origin    => 'ssh://gerrit.wikimedia.org:29418/analytics/geowiki/data-public.git',
        owner     => $::geowiki::params::user,
        group     => $::geowiki::params::user,
    }

    # cron job to do the actual fetching from the database, computation of
    # the limn files, and pushing the limn files to the data repositories
    cron { 'geowiki-process-db-to-limn':
        minute  => 0,
        hour    => 15,
        user    => $::geowiki::params::user,
        command => "${::geowiki::params::scripts_path}/scripts/make_and_push_limn_files.sh --cron-mode --basedir_public=${::geowiki::params::public_data_path} --basedir_private=${::geowiki::params::private_data_path} --source_sql_cnf=${::geowiki::mysql_conf::conf_file}",
        require => [
            Git::Clone['geowiki-scripts'],
            Git::Clone['geowiki-data-public'],
            Git::Clone['geowiki-data-private'],
            File[$::geowiki::mysql_conf::conf_file],
        ],
    }
}
