# SPDX-License-Identifier: Apache-2.0
#  Class that sets up and configures kubelet
class k8s::kubelet (
    K8s::KubernetesVersion $version,
    String $kubeconfig,
    Boolean $cni,
    String $pod_infra_container_image = 'docker-registry.discovery.wmnet/pause',
    Stdlib::Fqdn $cluster_domain = 'cluster.local',
    Stdlib::Unixpath $tls_cert = '/var/lib/kubernetes/ssl/certs/cert.pem',
    Stdlib::Unixpath $tls_key = '/var/lib/kubernetes/ssl/private_keys/server.key',
    Stdlib::Unixpath $cni_bin_dir = '/opt/cni/bin',
    Stdlib::Unixpath $cni_conf_dir = '/etc/cni/net.d',
    Boolean $logtostderr = true,
    Integer $v_log_level = 0,
    Boolean $kubelet_ipv6=false,
    Optional[Stdlib::IP::Address] $listen_address = undef,
    Optional[String] $docker_kubernetes_user_password = undef,
    Optional[Stdlib::IP::Address] $cluster_dns = undef, #FIXME: This should be an array of V4 addresses
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

    # Create the KubeletConfiguration YAML
    $config_yaml = {
        apiVersion        => 'kubelet.config.k8s.io/v1beta1',
        kind              => 'KubeletConfiguration',
        address           => $listen_address,
        tlsPrivateKeyFile => $tls_key,
        tlsCertFile       => $tls_cert,
        clusterDomain     => $cluster_domain,
        clusterDNS        => [$cluster_dns],
        featureGates      => if $kubelet_ipv6 { { 'IPv6DualStack' => true } },
        # FIXME: Do we really need anonymous read only access to kubelets enabled?
        #
        # When kubelet is run without --config, --read-only-port defaults to 10255 (e.g. is enabled).
        # Using --config the default changes to 0 (e.g. disabled).
        # 10255 is used by prometheus to scrape kubelet and cadvisor metrics.
        readOnlyPort => 10255,

        # --anonymous-auth which is enabled by default without --config but disabled when --config is used.
        # TODO: With k8s 1.23, the default for anonymous auth via --config changed back to 'true'
        authentication    => { anonymous => { enabled => true } },
        # Authorization mode defaults to 'AlwaysAllow' when running without --config but
        # 'Webhook' when --config is used.
        authorization     => { mode => 'AlwaysAllow' },
    }
    $config_file = '/etc/kubernetes/kubelet-config.yaml'
    file { $config_file:
        ensure  => file,
        owner   => 'kube',
        group   => 'kube',
        mode    => '0400',
        content => $config_yaml.filter |$k, $v| { $v =~ NotUndef and !$v.empty }.to_yaml,
        notify  => Service['kubelet'],
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
            File['/etc/default/kubelet'],
        ],
    }
}
