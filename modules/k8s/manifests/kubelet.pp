# SPDX-License-Identifier: Apache-2.0
#  Class that sets up and configures kubelet
class k8s::kubelet (
    K8s::KubernetesVersion $version,
    String $kubeconfig,
    Boolean $cni,
    Hash[String, Stdlib::Unixpath] $kubelet_cert,
    String $pod_infra_container_image,
    Stdlib::Fqdn $cluster_domain = 'cluster.local',
    Stdlib::Unixpath $cni_bin_dir = '/opt/cni/bin',
    Stdlib::Unixpath $cni_conf_dir = '/etc/cni/net.d',
    Integer $v_log_level = 0,
    Boolean $ipv6dualstack = false,
    Boolean $containerd_cri = false,
    Optional[Stdlib::IP::Address] $listen_address = undef,
    Optional[String] $docker_kubernetes_user_password = undef,
    Optional[Array[Stdlib::IP::Address,1]] $cluster_dns = undef,
    Optional[Array[String]] $node_labels = [],
    Optional[Array[K8s::Core::V1Taint]] $node_taints = [],
    Optional[Array[String]] $extra_params = undef,
    Optional[K8s::ReservedResource] $system_reserved = undef,
) {
    k8s::package { 'kubelet':
        package => 'node',
        version => $version,
    }
    # apparmor is needed for PodSecurityPolicy to be able to enforce profiles
    ensure_packages('apparmor')
    # socat is needed on k8s nodes for kubectl proxying to work
    ensure_packages('socat')

    # With k8s 1.23 we have aggregation layer support and can enable authentication/authorization
    # of requests against kubelet. Webhook mode uses the SubjectAccessReview API to determine authorization.
    $authentication = {
        anonymous => { enabled => false },
        webhook => { enabled => true },
        x509 => { clientCAFile => $kubelet_cert['chain'] },
    }
    $authorization = { mode => 'Webhook' }

    # Create the KubeletConfiguration YAML
    $config_yaml = {
        apiVersion         => 'kubelet.config.k8s.io/v1beta1',
        kind               => 'KubeletConfiguration',
        address            => $listen_address,
        tlsPrivateKeyFile  => $kubelet_cert['key'],
        tlsCertFile        => $kubelet_cert['cert'],
        clusterDomain      => $cluster_domain,
        clusterDNS         => $cluster_dns,
        # FIXME: Do we really need anonymous read only access to kubelets enabled?
        #
        # When kubelet is run without --config, --read-only-port defaults to 10255 (e.g. is enabled).
        # Using --config the default changes to 0 (e.g. disabled).
        # 10255 is used by prometheus to scrape kubelet and cadvisor metrics.
        readOnlyPort       => 10255,
        authentication     => $authentication,
        authorization      => $authorization,
        registerWithTaints => $node_taints,
        # Use systemd cgroup driver
        cgroupDriver       => 'systemd',
        # evictionHard is set to kubelet defaults apart from memory.available (which defaults to 100M)
        evictionHard       => {
            'imagefs.available' => '15%',
            'memory.available'  => '300M',
            'nodefs.available'  => '10%',
            'nodefs.inodesFree' => '5%',
        },
    }
    $config_file = '/etc/kubernetes/kubelet-config.yaml'
    $filtered_config_yaml = $config_yaml.filter |$k, $v| {
        $v ? {
            Undef   => false,
            Numeric => true,
            default => !$v.empty,
        }
    }
    file { $config_file:
        ensure  => file,
        owner   => 'kube',
        group   => 'kube',
        mode    => '0400',
        content => to_yaml($filtered_config_yaml),
        notify  => Service['kubelet'],
        require => K8s::Package['kubelet'],
    }

    file { '/etc/default/kubelet':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('k8s/kubelet.default.erb'),
        notify  => Service['kubelet'],
    }

    file { [
        '/var/run/kubernetes',
        '/var/lib/kubelet',
    ]:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0700',
    }

    if $docker_kubernetes_user_password {
        # TODO: pass the docker registry to this class as a variable.
        docker::credentials { '/var/lib/kubelet/config.json':
            owner             => 'root',
            group             => 'root',
            registry          => 'docker-registry.discovery.wmnet',
            registry_username => 'kubernetes',
            registry_password => $docker_kubernetes_user_password,
        }
    }

    service { 'kubelet':
        ensure    => running,
        enable    => true,
        subscribe => [
            File[$kubeconfig],
        ],
    }
    # Add a dependency from kubelet to the configured container runtime
    # The kubelet.service is shipped by the kubernetes-node debian package
    $container_runtime = $containerd_cri ? {
        true => 'containerd',
        default => 'docker',
    }
    systemd::override { 'container-runtime':
        ensure  => present,
        unit    => 'kubelet',
        restart => true,
        content => "[Unit]\nAfter=${container_runtime}.service\nRequires=${container_runtime}.service\n",
    }
}
