class k8s::scheduler(
    $master_host,
) {
    require_package('kube-scheduler')

    $master_ip = ipresolve($master_host, 4, $::nameservers[0])

    base::service_unit { 'kube-scheduler':
        systemd => true,
    }
}
