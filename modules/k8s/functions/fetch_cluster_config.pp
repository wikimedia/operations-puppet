# SPDX-License-Identifier: Apache-2.0
# This function reads the kubernetes cluster list from hiera and returns config for a specific cluster
function k8s::fetch_cluster_config (
  String $cluster_name,
) >> K8s::ClusterConfig {
  include k8s::clusters

  $k8s::clusters::by_cluster[$cluster_name]
}
