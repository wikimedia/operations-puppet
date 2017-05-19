# == Class profile::zookeeper::client
#
class profile::zookeeper::client(
    $clusters     = hiera('zookeeper_clusters'),
    $cluster_name = hiera('zookeeper_cluster_name'),
    $version      = hiera('profile::zookeeper::zookeeper_version'),
    $sync_limit   = hiera('profile::zookeeper::sync_limit'),
) {
    require_package('openjdk-7-jdk')

    class { '::zookeeper':
        hosts      => $clusters[$cluster_name]['hosts'],
        version    => $version,
        sync_limit => $sync_limit,
    }
}