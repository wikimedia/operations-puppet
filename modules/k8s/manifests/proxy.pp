class k8s::proxy(
    $master_host,
) {
    require_package('kube-proxy')

    $master_ip = ipresolve($master_host, 4, $::nameservers[0])

    base::service_unit { 'kube-proxy':
        systemd => true,
    }
}
