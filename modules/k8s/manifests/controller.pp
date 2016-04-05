class k8s::controller {
    include k8s::users

    base::service_unit { 'controller-manager':
        systemd => true,
    }
}
