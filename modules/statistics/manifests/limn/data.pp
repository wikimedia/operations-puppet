
# == Class statistics::limn::data
# Sets up base directories and repositories
# for using the statistics::limn::data::generate() define.
#
class statistics::limn::data {
    Class['::statistics::compute'] -> Class['::statistics::limn::data']
    Class['::statistics::user']    -> Class['::statistics::limn::data']

    $working_path      = '/srv'

    # Directory where the repository of the generate.py will be cloned.
    $source_dir        = "${working_path}/limn-mobile-data"

    # generate.py command to run in a cron.
    $command           = "${source_dir}/generate.py"

    # my.cnf credentials file. This is the file rendered by
    # mysql::config::client { 'stats-research': } defined in statistics::compute
    $mysql_credentials = '/etc/mysql/conf.d/stats-research-client.cnf'

    # cron job logs will be kept here
    $log_dir           = '/var/log/limn-data'

    # generate.py's repository
    $git_remote        = 'https://gerrit.wikimedia.org/r/p/analytics/limn-mobile-data.git'

    # public data directory.  Data will be synced from here to a public web host.
    $public_dir        = "${working_path}/limn-public-data"

    # Rsync generated data to stat1001 at http://datasets.wikimedia.org/limn-public-data/
    $rsync_to          = 'stat1001.eqiad.wmnet::www/limn-public-data/'

    # user to own files and run cron job as (stats).
    $user              = $::statistics::user::username

    # This path is used in the limn-mobile-data config.
    # Symlink this until they change it.
    # https://github.com/wikimedia/analytics-limn-mobile-data/blob/2321a6a0976b1805e79fecd495cf12ed7c6565a0/mobile/config.yaml#L5
    file { "${working_path}/.my.cnf.research":
        ensure  => 'link',
        target  => $mysql_credentials,
        require => Mysql::Config::Client['stats-research'],
    }

    # TODO:  This repository contains the generate.py script.
    # Other limn data repositories only have config and data
    # directories.  generate.py should be abstracted out into
    # a general purupose limn data generator.
    # For now, all limn data classes rely on this repository
    # and generate.py script to be present.
    if !defined(Git::Clone['analytics/limn-mobile-data']) {
        git::clone { 'analytics/limn-mobile-data':
            ensure    => 'latest',
            directory => $source_dir,
            origin    => $git_remote,
            owner     => $user,
            require   => [User[$user]],
        }
    }

    # Make sure these are writeable by $user.
    file { [$log_dir, $public_dir]:
        ensure => 'directory',
        owner  => $user,
        group  => wikidev,
        mode   => '0775',
    }

    # Rsync anything generated in $public_dir to $rsync_to
    cron { 'rsync_limn_public_data':
        command => "/usr/bin/rsync -rt ${public_dir}/* ${rsync_to}",
        user    => $user,
        minute  => 15,
    }
}
