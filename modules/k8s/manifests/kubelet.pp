# SPDX-License-Identifier: Apache-2.0
#  Class that sets up and configures kubelet
class k8s::kubelet (
    K8s::KubernetesVersion $version,
    String $kubeconfig,
    String $pod_infra_container_image,
    String $listen_address,
    Boolean $cni,
    Optional[String] $docker_kubernetes_user_password = undef,
    Optional[Stdlib::Port] $listen_port = undef,
    String $cluster_domain = 'kube',
    Optional[String] $cluster_dns = undef,
    String $tls_cert = '/var/lib/kubernetes/ssl/certs/cert.pem',
    String $tls_key = '/var/lib/kubernetes/ssl/private_keys/server.key',
    String $cni_bin_dir = '/opt/cni/bin',
    String $cni_conf_dir = '/etc/cni/net.d',
    Boolean $logtostderr = true,
    Integer $v_log_level = 0,
    Boolean $kubelet_ipv6=false,
    Optional[Array[String]] $node_labels = [],
    Optional[Array[String]] $node_taints = [],
    Optional[Array[String]] $extra_params = undef,
) {
    k8s::package { 'kubelet':
        package => 'node',
        version => $version,
    }
    # apparmor is needed for PodSecurityPolicy to be able to enforce profiles
    ensure_packages('apparmor')
    # socat is needed on k8s nodes for kubectl proxying to work
    ensure_packages('socat')

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
            File['/etc/default/kubelet'],
        ],
    }
}
