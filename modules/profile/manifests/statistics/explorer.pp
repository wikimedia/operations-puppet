# == Class profile::statistics::explorer
#
class profile::statistics::explorer(
    $statistics_servers = hiera('statistics_servers'),
) {
    include ::standard
    include ::base::firewall

    include ::deployment::umask_wikidev

    class { '::statistics':
        servers      => $statistics_servers,
    }

    # include stuff common to statistics compute nodes
    include ::statistics::compute

    # Include the MySQL research password at
    # /etc/mysql/conf.d/analytics-research-client.cnf
    # and only readable by users in the
    # analytics-privatedata-users group.
    statistics::mysql_credentials { 'analytics-research':
        group => 'analytics-privatedata-users',
    }
}