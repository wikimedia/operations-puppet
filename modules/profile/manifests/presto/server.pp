# == Class profile::presto::server
#
# Sets up a presto server in a presto cluster.
# By default this node will be set up as a worker node.  To enable the
# coordinator or discovery, provide appropriate settings in $config_properties.
#
# See also: https://prestodb.io/docs/current/installation/deployment.html
#
# == Parameters
#
# [*cluster_name*]
#   Name of the Presto cluster.  This will be used as the default node.environment.
#
# [*discovery_uri*]
#   URI to the Presto discovery server.
#
# [*node_properties*]
#   Specific node.properties settings. This profile attempts to use sane defaults.
#   Only set this if you need to override them.  Note that node.id will be
#   set automatically by the presto::server module class based on the current node's
#   $::fqdn.
#
# [*config_properties*]
#   Specific config.properties settings. This profile attempts to use sane defaults.
#   Only set this if you need to override them.
#
# [*log_properties*]
#   Specific log.properties settings.
#
# [*heap_max*]
#   -Xmx argument. Default: 2G
#
class profile::presto::server(
    String $cluster_name      = hiera('profile::presto::cluster_name'),
    String $discovery_uri     = hiera('profile::presto::discovery_uri'),
    Hash   $node_properties   = hiera('profile::presto::server::node_properties',   {}),
    Hash   $config_properties = hiera('profile::presto::server::config_properties', {}),
    Hash   $catalogs          = hiera('profile::presto::server::catalogs',          {}),
    Hash   $log_properties    = hiera('profile::presto::server::log_properties',    {}),
    String $heap_max          = hiera('profile::presto::server::heap_max',          '2G'),
) {

    $default_node_properties = {
        'node.enviroment' => $cluster_name,
        'node.data-dir'   => '/srv/presto',
    }

    $default_config_properties = {
        'http-server.http.port'              => 8280,
        'discovery.uri'                      => $discovery_uri,
        # flat will try to schedule splits on the host where the data is located by reserving
        # 50% of the work queue for local splits. It is recommended to use flat for clusters
        # where distributed storage runs on the same nodes as Presto workers.
        # You should change this if your Presto cluster is not colocated with storage.
        'node-scheduler.network-topology'    => 'flat',
    }

    class { '::presto::server':
        # Merge in any overrides for config.properties
        node_properties   => $default_node_properties + $node_properties,
        config_properties => $default_config_properties + $config_properties,
        log_properties    => $log_properties,
        catalogs          => $catalogs,
        heap_max          => $heap_max,
    }
}
