# SPDX-License-Identifier: Apache-2.0
# @summary
#   This class sets up and configures kube-apiserver
#
# === Parameters
# @param [K8s::KubernetesVersion] version
#   The Kubernetes version to use.
#
# @param [String] etcd_servers
#   Comma separated list of etcd server URLs.
#
# @param [Hash[String, Stdlib::Unixpath]] apiserver_cert
#   The certificate used for the apiserver.
#
# @param [Hash[String, Stdlib::Unixpath]] sa_cert
#   The certificate used for service account management (signing).
#
# @param [Hash[String, Stdlib::Unixpath]] kubelet_client_cert
#   The certificate used to authenticate against kubelets.
#
# @param [Hash[String, Stdlib::Unixpath]] frontproxy_cert
#   The certificate used for the front-proxy.
#   https://v1-23.docs.kubernetes.io/docs/tasks/extend-kubernetes/configure-aggregation-layer/
#
# @param [Stdlib::HTTPSUrl] service_account_issuer
#   The HTTPS URL of the service account issuer (usually the control-plane URL).
#
# @param [K8s::ClusterCIDR] service_cluster_cidr
#     CIDRs (IPv4, IPv6) used to allocate Service IPs.
#
# @param [Boolean] allow_privileged
#   Whether to allow privileged containers. Defaults to true as this is required for calico to run.
#
# @param [Integer] v_log_level
#   The log level for the API server. Defaults to 0.
#
# @param [Boolean] ipv6dualstack
#   Whether to enable IPv6 dual stack support. Defaults to false.
#
# @param [Optional[String]] audit_policy
#   The audit policy configuration to use for the cluster. This is a string that corresponds to the filename
#   of a full audit policy file in modules/k8s/files/
#   Audit logging is disabled if this is not set.
#
# @param service_node_port_range
#   Optional port range (as first and last port, including) to reserve for services with NodePort visibility.
#   Defaults to 30000-32767 if undef.
#
# @param admission_plugins
#   Optional admission plugins that should be enabled or disabled. Defaults to undef.
#   Some plugins are enabled by default and need to be explicitely disabled.
#   The defaults depend on the kubernetes version, see:
#   `kube-apiserver -h | grep admission-plugins`.
#
# @param admission_configuration
#   Optional array of admission plugin configurations (as YAML). Defaults to undef.
#   https://kubernetes.io/docs/reference/config-api/apiserver-config.v1alpha1/#apiserver-k8s-io-v1alpha1-AdmissionPluginConfiguration
#
# @param [Hash[String, Stdlib::Unixpath]] additional_sa_certs
#   Optional array of certificate keys for validation of service account tokens.
#   These will be used in addition to sa_cert.
#
class k8s::apiserver (
    K8s::KubernetesVersion $version,
    String $etcd_servers,
    Hash[String, Stdlib::Unixpath] $apiserver_cert,
    Hash[String, Stdlib::Unixpath] $sa_cert,
    Hash[String, Stdlib::Unixpath] $kubelet_client_cert,
    Hash[String, Stdlib::Unixpath] $frontproxy_cert,
    Stdlib::HTTPSUrl $service_account_issuer,
    K8s::ClusterCIDR $service_cluster_cidr,
    Boolean $allow_privileged = true,
    Integer $v_log_level = 0,
    Boolean $ipv6dualstack = false,
    String $audit_policy = '',
    Optional[Array[Stdlib::Port, 2, 2]] $service_node_port_range = undef,
    Optional[K8s::AdmissionPlugins] $admission_plugins = undef,
    Optional[Array[Hash]] $admission_configuration = undef,
    Optional[Array[Stdlib::Unixpath]] $additional_sa_certs = undef,
) {
    # etcd-client is used to orchestrate kube-apiserver restarts
    # with the kube-apiserver-safe-restart systemd service
    ensure_packages('etcd-client')
    k8s::package { 'apiserver':
        package => 'master',
        version => $version,
    }

    # Create log folder for kube-apiserver audit logs
    file { '/var/log/kubernetes/':
        ensure  => directory,
        owner   => 'kube',
        require => K8s::Package['apiserver'],
    }
    $enable_audit_log = $audit_policy ? {
        undef   => false,
        ''      => false,
        default => true,
    }
    $audit_policy_file = '/etc/kubernetes/audit-policy.yaml'
    file { $audit_policy_file:
        ensure  => stdlib::ensure($enable_audit_log, 'file'),
        owner   => 'kube',
        group   => 'kube',
        mode    => '0444',
        source  => "puppet:///modules/k8s/${audit_policy}",
        notify  => Service['kube-apiserver-safe-restart'],
        require => K8s::Package['apiserver'],
    }

    # The admission config file needs to be available as parameter fo apiserver
    $admission_configuration_file = '/etc/kubernetes/admission-config.yaml'
    file { '/etc/default/kube-apiserver':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('k8s/kube-apiserver.default.erb'),
        notify  => Service['kube-apiserver-safe-restart'],
    }

    $admission_configuration_ensure = $admission_configuration ? {
        undef   => absent,
        default => file,
    }
    # .to_yaml in erb templates always adds a document separator so it's
    # not possible to join yaml in the template with .to_yaml from a variable.
    $admission_configuration_content = {
        apiVersion => 'apiserver.config.k8s.io/v1',
        kind       => 'AdmissionConfiguration',
        plugins    => $admission_configuration,
    }
    file { $admission_configuration_file:
        ensure  => $admission_configuration_ensure,
        content => to_yaml($admission_configuration_content),
        owner   => 'kube',
        group   => 'kube',
        mode    => '0400',
        notify  => Service['kube-apiserver-safe-restart'],
        require => K8s::Package['apiserver'],
    }

    service { 'kube-apiserver':
        ensure => running,
        enable => true,
    }

    # Create a oneshot service that should be used for restarting kube-apiserver.
    # It uses a etcd lock to ensure only one apiserver is restarted at the time
    systemd::service { 'kube-apiserver-safe-restart':
        ensure  => present,
        content => template('k8s/kube-apiserver-safe-restart.systemd.erb'),
    }
}
