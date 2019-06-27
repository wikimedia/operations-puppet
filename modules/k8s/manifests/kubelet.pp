class k8s::kubelet(
    String $listen_address = '0.0.0.0',
    Optional[Stdlib::Port] $listen_port = undef,
    String $pod_infra_container_image = 'gcr.io/google_containers/pause:2.0',
    String $cluster_domain = 'kube',
    String $tls_cert = '/var/lib/kubernetes/ssl/certs/cert.pem',
    String $tls_key = '/var/lib/kubernetes/ssl/private_keys/server.key',
    Boolean $cni = false,
    String $cni_bin_dir = '/opt/cni/bin',
    String $cni_conf_dir = '/etc/cni/net.d',
    String $kubeconfig = '/etc/kubernetes/kubeconfig',
    Optional[Array[String]] $node_labels = [],
    Optional[Array[String]] $node_taints = [],
    Optional[Array[String]] $extra_params = undef,
) {
    require_package('kubernetes-node')

    # Needed on k8s nodes for kubectl proxying to work
    ensure_packages(['socat'])

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
    ] :
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0700',
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
