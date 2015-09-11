class k8s::controller {
    require_package('kube-controller-manager')

    base::service_unit { 'controller-manager':
        systemd => true,
    }
}
