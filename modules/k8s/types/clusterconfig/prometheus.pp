# SPDX-License-Identifier: Apache-2.0
# @type K8s::ClusterConfig::Prometheus
# Define the prometheus configuration for a kubernetes cluster
# @param [Optional[String]] name
#     The name of the prometheus instance (LVS name).
#     If not given, the name of the kubernetes cluster will be used, prefixed by "k8s-"
# @param [Stdlib::Port] port
#     TCP port for the prometheus instance. This must be unique per DC.
# @param [Optional[String]] retention
#     The time-based retention for this prometheus instance
# @param [Optional[Stdlib::Datasize]] retention
#     The space-based retention for this prometheus instance.
#     Overrides 'retention' when specified.

type K8s::ClusterConfig::Prometheus = Struct[{
  'name'                     => Optional[String[1]],
  'port'                     => Stdlib::Port,
  'retention'                => Optional[String[1]],
  'retention_size'           => Optional[Stdlib::Datasize],
}]
