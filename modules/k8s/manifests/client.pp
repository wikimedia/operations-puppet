# Class that sets up and configures kubectl
class k8s::client(
    Boolean $packages_from_future = false,
) {

    if $packages_from_future {
        apt::package_from_component { 'kubectl-kubernetes-future':
            component => 'component/kubernetes-future',
            packages  => ['kubernetes-client'],
        }
    } else {
        require_package('kubernetes-client')
    }
}
