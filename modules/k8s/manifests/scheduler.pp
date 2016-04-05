class k8s::scheduler {
    include k8s::users

    base::service_unit { 'kube-scheduler':
        systemd => true,
    }
}
