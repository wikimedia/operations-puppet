# SPDX-License-Identifier: Apache-2.0
# This function returns the kubernetes clusters from hiera by cluster_group
function k8s::fetch_cluster_groups () >> Hash[String, Hash[String, K8s::ClusterConfig]] {
  include k8s::clusters

  $k8s::clusters::by_group
}
