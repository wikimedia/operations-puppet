# == Class profile::presto::client
#
# == Parameters
#
# [*presto_clusters*]
#   hash of presto clusters and configuration, keyed by cluster name.
#   See documentation of this parameter in profile::presto::server for more information.
#   This class only needs to know the discovery.uri of the presto cluster.
#
# [*cluster_name*]
#   Key in $presto_clusters that indicates which configuration to use for this Presto cluster.
#
class profile::presto::client(
    Hash   $presto_clusters = hiera('presto_clusters'),
    String $cluster_name    = hiera('profile::presto::cluster_name'),
) {
    $presto_config = $presto_clusters[$cluster_name]

    class { '::presto::client':
        discovery_uri => $presto_config['properties']['config']['discovery.uri'],
    }
}
