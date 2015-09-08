class k8s::apiserver(
    $etcd_servers,
    $master_host,
) {
    require_package('kube-apiserver')

    $master_ip = ipresolve($master_host, 4, $::nameservers[0])
    base::service_unit { 'kube-apiserver':
        systemd => true,
    }
}
