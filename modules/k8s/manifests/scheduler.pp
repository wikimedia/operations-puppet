class k8s::scheduler {
    require_package('kube-scheduler')

    include k8s::users

    base::service_unit { 'kube-scheduler':
        systemd => true,
    }
}
