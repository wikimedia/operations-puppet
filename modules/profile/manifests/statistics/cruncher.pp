# == Class profile::statistics::cruncher
#
class profile::statistics::cruncher(
    $statistics_servers = hiera('statistics_servers'),
    $dumps_servers       = hiera('dumps_dist_nfs_servers'),
    $dumps_active_server = hiera('dumps_dist_active_web'),
) {

    require ::profile::analytics::cluster::packages::statistics

    include ::profile::analytics::cluster::gitconfig

    include ::deployment::umask_wikidev

    include ::profile::backup::host
    backup::set { 'home' : }

    class { '::statistics':
        servers      => $statistics_servers,
    }

    # include stuff common to statistics compute nodes
    include ::statistics::compute

    class { '::statistics::dataset_mount':
        dumps_servers       => $dumps_servers,
        dumps_active_server => $dumps_active_server,
    }

    # This file will render at
    # /etc/mysql/conf.d/researchers-client.cnf.
    # This is so that users in the researchers
    # group can access the research slave dbs.
    statistics::mysql_credentials { 'research':
        group => 'researchers',
    }

    # rsync logs from logging hosts
    include ::statistics::rsync::eventlogging
}
