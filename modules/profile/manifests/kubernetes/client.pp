# SPDX-License-Identifier: Apache-2.0
# Simple profile class for installing the proper version of kubectl
# NOTE: Resist the urge to just old it in some other profile, it's been split
# off in its own profile so that it can be reused in e.g. deployment servers
class profile::kubernetes::client (
    K8s::KubernetesVersion $version = lookup('profile::kubernetes::version', { default_value => '1.16' }),
) {
    class { 'k8s::client':
        version => $version,
    }
}
