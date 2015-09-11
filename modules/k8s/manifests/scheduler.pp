class k8s::scheduler {
    require_package('kube-scheduler')

    base::service_unit { 'kube-scheduler':
        systemd => true,
    }
}
