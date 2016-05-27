class k8s::proxy(
    $master_host,
) {
    include ::k8s::infrastructure_config

    $master_ip = ipresolve($master_host, 4, $::nameservers[0])

    base::service_unit { 'kube-proxy':
        systemd   => true,
        upstart   => true,
        subscribe => File['/etc/kubernetes/kubeconfig'],
    }
}
