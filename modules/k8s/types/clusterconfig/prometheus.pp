# SPDX-License-Identifier: Apache-2.0
# @type K8s::ClusterConfig::Prometheus
# Define the prometheus configuration for a kubernetes cluster
# @param [Optional[String]] name
#     The name of the prometheus instance (LVS name).
#     If not given, the name of the kubernetes cluster will be used, prefixed by "k8s-"
# @param [Stdlib::Port] port
#     TCP port for the prometheus instance. This must be unique per DC.
# @param [String] node_class_name
#     The name of the puppet class used for kubernetes nodes.
#     Prometheus will use this to query nodes from puppetdb.
# @param [String] control_plane_class_name
#     The name of the puppet class used for kubernetes control-planes.
#     Prometheus will use this to query control-planes from puppetdb.
type K8s::ClusterConfig::Prometheus = Struct[{
  'name'                     => Optional[String[1]],
  'port'                     => Stdlib::Port,
  'node_class_name'          => String[1],
  'control_plane_class_name' => String[1],
}]
