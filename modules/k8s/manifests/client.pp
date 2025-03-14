# SPDX-License-Identifier: Apache-2.0
# Class that sets up and configures kubectl
class k8s::client (
    K8s::KubernetesVersion $version,
) {
    k8s::package { 'kubectl':
        package => 'client',
        version => $version,
    }
}
