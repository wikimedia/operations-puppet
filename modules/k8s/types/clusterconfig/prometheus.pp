# SPDX-License-Identifier: Apache-2.0
# @type K8s::ClusterConfig::Prometheus
# Define the prometheus configuration for a kubernetes cluster
# @param [Optional[String]] name
#     The name of the prometheus instance (LVS name).
#     If not given, the name of the kubernetes cluster will be used, prefixed by "k8s-"
# @param [Stdlib::Port] port
#     TCP port for the prometheus instance. This must be unique per DC.
type K8s::ClusterConfig::Prometheus = Struct[{
  'name'                     => Optional[String[1]],
  'port'                     => Stdlib::Port,
}]
