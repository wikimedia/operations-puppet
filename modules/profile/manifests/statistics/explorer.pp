# == Class profile::statistics::explorer
#
class profile::statistics::explorer(
    $statistics_servers = hiera('statistics_servers'),
) {

    require ::profile::analytics::cluster::packages::statistics
    require ::profile::analytics::cluster::repositories::statistics
    include ::profile::analytics::cluster::gitconfig

    class { '::deployment::umask_wikidev': }

    class { '::statistics':
        servers      => $statistics_servers,
    }

    # include stuff common to statistics compute nodes
    class { '::statistics::compute': }

    # Include the MySQL research password at
    # /etc/mysql/conf.d/analytics-research-client.cnf
    # and only readable by users in the
    # analytics-privatedata-users group.
    statistics::mysql_credentials { 'analytics-research':
        group => 'analytics-privatedata-users',
    }
}