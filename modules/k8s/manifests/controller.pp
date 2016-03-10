class k8s::controller {
    require_package('kube-controller-manager')
    require ::k8s::ssl

    include k8s::users

    base::service_unit { 'controller-manager':
        systemd => true,
    }
}
