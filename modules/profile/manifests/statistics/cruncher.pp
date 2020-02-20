# == Class profile::statistics::cruncher
#
class profile::statistics::cruncher(
    $statistics_servers = hiera('statistics_servers'),
) {

    require ::profile::analytics::cluster::packages::statistics
    require ::profile::analytics::cluster::repositories::statistics

    include ::profile::analytics::cluster::gitconfig

    include ::deployment::umask_wikidev

    class { '::statistics':
        servers      => $statistics_servers,
    }

    # include stuff common to statistics compute nodes
    include ::statistics::compute

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
