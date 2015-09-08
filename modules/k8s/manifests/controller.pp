class k8s::controller(
    $master_host,
) {
    require_package('kube-controller-manager')

    $master_ip = ipresolve($master_host, 4, $::nameservers[0])
    base::service_unit { 'controller-manager':
        systemd => true,
    }
}
