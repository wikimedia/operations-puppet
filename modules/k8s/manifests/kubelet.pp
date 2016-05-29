class k8s::kubelet(
    $master_host,
    $cluster_dns_ip = '192.168.0.100',
    $pod_infra_container_image = 'gcr.io/google_containers/pause:2.0',
) {
    include ::k8s::infrastructure_config

    file { [
        '/var/run/kubernetes',
        '/var/lib/kubelet',
    ] :
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0700',
    }

    base::service_unit { 'kubelet':
        systemd   => true,
        subscribe => File['/etc/kubernetes/kubeconfig'],
    }
}
