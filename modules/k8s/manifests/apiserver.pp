# SPDX-License-Identifier: Apache-2.0
# @summary
#   This class sets up and configures kube-apiserver
#
# === Parameters
# @param version
#   The Kubernetes version to use
# @param admission_plugins
#   Admission plugins that should be enabled or disabled.
#   Some plugins are enabled by default and need to be explicitely disabled.
#   The defaults depend on the kubernetes version, see:
#   `kube-apiserver -h | grep admission-plugins`.
#
# @param admission_configuration
#   Array of admission plugin configurations (as YAML)
#   https://kubernetes.io/docs/reference/config-api/apiserver-config.v1alpha1/#apiserver-k8s-io-v1alpha1-AdmissionPluginConfiguration
class k8s::apiserver (
    K8s::KubernetesVersion $version,
    String $etcd_servers,
    Hash[String, Stdlib::Unixpath] $apiserver_cert,
    Hash[String, Stdlib::Unixpath] $sa_cert,
    Hash[String, Stdlib::Unixpath] $kubelet_client_cert,
    Hash[String, Stdlib::Unixpath] $frontproxy_cert,
    Stdlib::HTTPSUrl $service_account_issuer,
    Hash[String, Any] $users,
    K8s::ClusterCIDR $service_cluster_cidr,
    Boolean $allow_privileged = false,
    Integer $v_log_level = 0,
    Boolean $ipv6dualstack = false,
    Optional[String] $service_node_port_range = undef,
    Optional[String] $runtime_config = undef,
    Optional[K8s::AdmissionPlugins] $admission_plugins = undef,
    Optional[Array[Hash]] $admission_configuration = undef,
    Optional[Array[Stdlib::Unixpath]] $additional_sa_certs = undef,
) {
    group { 'kube':
        ensure => present,
        system => true,
    }
    user { 'kube':
        ensure => present,
        gid    => 'kube',
        system => true,
        home   => '/nonexistent',
        shell  => '/usr/sbin/nologin',
    }

    k8s::package { 'apiserver':
        package => 'master',
        version => $version,
    }

    file { '/etc/kubernetes/infrastructure-users':
        content => template('k8s/infrastructure-users.csv.erb'),
        owner   => 'kube',
        group   => 'kube',
        mode    => '0400',
        notify  => Service['kube-apiserver'],
    }

    # The admission config file needs to be available as parameter fo apiserver
    $admission_configuration_file = '/etc/kubernetes/admission-config.yaml'
    file { '/etc/default/kube-apiserver':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('k8s/kube-apiserver.default.erb'),
        notify  => Service['kube-apiserver'],
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
        notify  => Service['kube-apiserver'],
    }

    service { 'kube-apiserver':
        ensure => running,
        enable => true,
    }
}
