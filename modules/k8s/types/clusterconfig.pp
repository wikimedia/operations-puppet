# SPDX-License-Identifier: Apache-2.0
# @type K8s::ClusterConfig
# Define the generic (e.g. required by control-plane and workers) configuration of a kubernetes cluster
#
# @param [String] dc
#     The datacenter of this cluster
#
# @param [String] cluster_alias
#     An optional alias for this cluster. kubeconfig files will be generated with this name.
#
# @param [String] cluster_group
#     The kubernetes cluster groups the cluster belongs to.
#     Will be auto generated in class k8s::clusters.
#
# @param [Stdlib::Fqdn] master
#     The FQDN of the control-plane (usually an LVS service)
#
# @param [Stdlib:Port] master_port
#     The port to use when generating master_url
#
# @param [Stdlib::HTTPSUrl] master_url
#     HTTPS URL of the DC local apiserver.
#     Will be auto generated in class k8s::clusters.
#
# @param [K8s::KubernetesVersion] version
#     The kubernetes version running this cluster
#
# @param [Cfssl::Ca_name] pki_intermediate_base
#     The base name of the intermediate used for this cluster
#     It is expected that there a PKI intermediate with this name exists as well as a second
#     intermediate suffixed with _front_proxy which is used to configure the aggregation layer.
#     E.g. by setting "wikikube" here you are required to add the intermediates "wikikube"
#     and "wikikube_front_proxy" to PKI.
#
# @param [Integer] pki_renew_seconds
#     Certificates will be renewed if they are due to expire in this many seconds.
#     952200 seconds is the default from cfssl::cert:
#     the default https checks go warning after 10 full days i.e. anywhere
#     from 864000 to 950399 seconds before the certificate expires.  As such set this to
#     11 days + 30 minutes to capture the puppet run schedule.
#
# @param [Array[Stdlib::Host, 1]] control_plane_nodes
#     FQDNs of all control-plane (master) nodes.
#
# @param [Array[Stdlib::IP::Address, 1]] cluster_dns
#     IPv4 IP(s) of cluster internal DNS service(s).
#     It needs to be in your clusters service IP range.
#     Don't use .1 as it is used internally by kubernetes.
#
# @param [K8s::ClusterCIDR] service_cluster_cidr
#     CIDRs (IPv4, IPv6) used to allocate Service IPs.
#     This must not overlap with any IP ranges assigned to nodes or pods.
#
# @param [K8s::ClusterCIDR] cluster_cidr
#     CIDRs (IPv4, IPv6) used to allocate Pod IPs.
#
# @param [Optional[Array[Stdlib::HTTPSUrl, 3]]] etcd_urls
#     URLs of all etcd nodes for this cluster.
#     Might be empty if this this cluster runs stacked control-planes.
#
# @param [Array[Stdlib::Port, 2, 2]] service_node_port_range
#     A port range to reserve for services with NodePort visibility.
#     This must not overlap with the ephemeral port range on nodes.
#
# @param [Boolean] ipv6dualstack
#     Enable IPv6 (dual-stack) support.
#
# @param [String[1]] infra_pod
#     Container image URL to use as pause container.
#
# @param [Boolean] use_cni
#     Enable CNI (FIXME: Remove this one when migrating away from dockershim
#     as the kubelet commandline options we derive from this are dockershim only).
#
# @param [Array[Hash]] admission_configuration
#   Array of admission plugin configurations (as YAML)
#   https://kubernetes.io/docs/reference/config-api/apiserver-config.v1alpha1/#apiserver-k8s-io-v1alpha1-AdmissionPluginConfiguration
#
# @param [K8s::AdmissionPlugins] admission_plugins
#   Admission plugins that should be enabled or disabled.
#   Some plugins are enabled by default and need to be explicitely disabled.
#   The defaults depend on the kubernetes version, see:
#   `kube-apiserver -h | grep admission-plugins`.
#
# @param [Array[Stdlib::Host, 1]] cluster_nodes
#   All nodes of the cluster.
#
# @param [Calico::CalicoVersion] calico_version
#   Calico version to use.
#
# @param [String[1]] istio_cni_version
#   Istio CNI version to use.
#
# @param [Hash] cni_config
#   CNI configuration for kubelet.
#
# @param [Boolean] imagecatalog
#   Enable imagecatalog scanning on this cluster.
#
# @param [Optional[K8s::ClusterConfig::Prometheus]] prometheus
#   Configuration of the prometheus instances for this cluster
#
# @param [Optional[Array[String]] apparmor_profiles
#   A list of apparmor profiles to populate in the cluster. The actual profiles
#   will need to be placed in modules/profile/files/kubernetes/node/ and are
#   referenced by filename
#
# @param [Optional[String]] audit_policy
#   The audit policy configuration to use for the cluster. This is a string that corresponds to the filename
#   of a full audit policy file in modules/k8s/files/
#   Audit logging is disabled if this is not set.

type K8s::ClusterConfig = Struct[{
  'dc'                      => String[1],
  'cluster_alias'           => Optional[String[1]],
  'cluster_group'           => String[1],
  'master'                  => Stdlib::Fqdn,
  'master_port'             => Stdlib::Port,
  'master_url'              => Stdlib::HTTPSUrl,
  'version'                 => K8s::KubernetesVersion,
  'pki_intermediate_base'   => Cfssl::Ca_name,
  'pki_renew_seconds'       => Integer[1800],
  'control_plane_nodes'     => Array[Stdlib::Host, 1],
  'cluster_dns'             => Array[Stdlib::IP::Address, 1],
  'service_cluster_cidr'    => K8s::ClusterCIDR,
  'cluster_cidr'            => K8s::ClusterCIDR,
  'etcd_urls'               => Optional[Array[Stdlib::HTTPSUrl, 3]],
  'service_node_port_range' => Array[Stdlib::Port, 2, 2],
  'ipv6dualstack'           => Boolean,
  'infra_pod'               => String[1],
  'use_cni'                 => Boolean,
  'admission_configuration' => Optional[Array[Hash]],
  'admission_plugins'       => K8s::AdmissionPlugins,
  'cluster_nodes'           => Array[Stdlib::Host, 1],
  'calico_version'          => Calico::CalicoVersion,
  # TODO: istio_cni_version should have it's own type, validating available versions
  'istio_cni_version'       => String[1],
  'cni_config'              => Hash,
  'imagecatalog'            => Boolean,
  'prometheus'              => Optional[K8s::ClusterConfig::Prometheus],
  'apparmor_profiles'       => Optional[Array[String]],
  'audit_policy'            => Optional[String],
}]
