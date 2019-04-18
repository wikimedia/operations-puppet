class k8s::kubelet(
    $listen_address = '0.0.0.0',
    $listen_port = undef,
    $pod_infra_container_image = 'gcr.io/google_containers/pause:2.0',
    $cluster_domain = 'kube',
    $tls_cert = '/var/lib/kubernetes/ssl/certs/cert.pem',
    $tls_key = '/var/lib/kubernetes/ssl/private_keys/server.key',
    $cni = false,
    $cni_bin_dir = '/opt/cni/bin',
    $cni_conf_dir = '/etc/cni/net.d',
    $kubeconfig = '/etc/kubernetes/kubeconfig',
    $node_labels = [],
    $node_taints = [],
    $extra_params = undef,
) {
    require ::k8s::infrastructure_config

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
