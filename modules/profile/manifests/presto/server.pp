# == Class profile::presto::server
#
# Sets up a presto server in a presto cluster.
#
# With no $config_overrides, this server will
# be both a 'coordinator' and a 'worker' server.  It will accept queries from
# clients and also allow scheduling of work on itself.
#
# To use this as either only a coordinator or a worker, set the appropriate
# $config_overrides: coordinator, node-scheduler.include-coordinator and discovery-server.enabled.
# See also: https://prestodb.io/docs/current/installation/deployment.html
#
# == Parameters
#
# [*presto_clusters*]
#   hash of presto clusters and configuration, keyed by cluster name.
#   Each cluster entry should have 3 top level configurations:
#   'nodes', which maps hostnames to ids, 'catalogs', which maps Presto
#   catalog names to catalog .properties files, and 'properties', which itself
#   is used to render the various Presto server .properties files. The
#   'properties' hash can have 3 entries: 'config', 'node', and 'log',
#   each respectively for rendering config.properties, node.properties,
#   and log.properties.
#
# [*cluster_name*]
#   Key in $presto_clusters that indicates which configuration to use for this Presto cluster.
#
# [*heap_max*]
#   -Xmx argument. Default: 2G
#
# [*config_overrides*]
#   Overrides for config.properties.  This should be a hash of config.properties keys
#   to values.  Anything here will override properties found in
#   $presto_clusters[$cluster_name]['properties']['config'].  Default: {}
#
class profile::presto::server(
    Hash   $presto_clusters  = hiera('presto_clusters'),
    String $cluster_name     = hiera('profile::presto::cluster_name'),
    String $heap_max         = hiera('profile::presto::server::heap_max',          '2G'),
    Hash   $config_overrides = hiera('profile::presto::server::config_overrides',  {}),
) {

    $presto_config = $presto_clusters[$cluster_name]

    # Merge in any overrides for config.properties
    $config_properties = $presto_config['properties']['config'] + $config_overrides

    # Use common node.properties + the specific node.id for this hostname.
    # $presto_config['nodes'] MUST contain an entry for this hostname that maps
    # to a hash that includes an 'id' entry to specify the node.id for this hostname.
    $node_properties = $presto_config['properties']['node'] + {
        'node.id' => $presto_config['nodes'][$::hostname]['id']
    }

    # Don't set any log properties if none given
    if 'log' in $presto_config['properties'] {
        $log_properties = $presto_config['properties']['log']
    }
    else {
        $log_properties = {}
    }

    class { '::presto::server':
        config_properties => $config_properties,
        node_properties   => $node_properties,
        log_properties    => $log_properties,
        catalogs          => $presto_config['catalogs'],
        heap_max          => $heap_max,
    }
}
