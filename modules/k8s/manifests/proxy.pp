class k8s::proxy(
    $master_host,
) {
    include ::k8s::infrastructure_config
    require_package('kube-proxy')

    $master_ip = ipresolve($master_host, 4, $::nameservers[0])

    include k8s::users

    base::service_unit { 'kube-proxy':
        systemd   => true,
        subscribe => File['/etc/kubernetes/kubeconfig'],
    }
}
