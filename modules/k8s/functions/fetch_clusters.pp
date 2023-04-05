# SPDX-License-Identifier: Apache-2.0
# This function returns the kubernetes cluster list from hiera
# Takes a Boolean parameter: include_aliases.
# If set to true, (default) cluster aliases will be returned
# If set to false, only real clusters will be returned (no aliases)
function k8s::fetch_clusters (
    Boolean $include_aliases=true,
) >> Hash[String, K8s::ClusterConfig] {
  include k8s::clusters

  if $include_aliases {
    $k8s::clusters::by_cluster
  } else {
    $k8s::clusters::by_cluster.filter |$name, $config| {
      $config['cluster_alias'] != $name
    }
  }
}
