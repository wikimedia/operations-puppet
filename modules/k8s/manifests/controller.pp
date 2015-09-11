class k8s::controller {
    require_package('kube-controller-manager')

    include k8s::users

    base::service_unit { 'controller-manager':
        systemd => true,
    }
}
