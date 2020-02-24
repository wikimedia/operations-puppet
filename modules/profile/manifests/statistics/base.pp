# == Class profile::statistics::base
#
class profile::statistics::base(
    $statistics_servers = hiera('statistics_servers'),
) {

    require ::profile::analytics::cluster::packages::statistics
    require ::profile::analytics::cluster::repositories::statistics

    include ::profile::analytics::cluster::gitconfig

    class { '::statistics':
        servers      => $statistics_servers,
    }

    # include stuff common to statistics compute nodes
    class { 'statistics::compute': }
}
