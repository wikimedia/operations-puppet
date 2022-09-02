# SPDX-License-Identifier: Apache-2.0
# Class that sets up and configures kubectl
class k8s::client(
    Boolean $packages_from_future = false,
) {

    if $packages_from_future {
        if debian::codename::le('buster'){
            apt::package_from_component { 'kubectl-kubernetes-future':
                component => 'component/kubernetes-future',
                packages  => ['kubernetes-client'],
            }
        } else {
            apt::package_from_component { 'kubectl-kubernetes116':
                component => 'component/kubernetes116',
                packages  => ['kubernetes-client'],
            }
        }
    } else {
        ensure_packages('kubernetes-client')
    }
}
