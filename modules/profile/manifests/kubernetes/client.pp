# SPDX-License-Identifier: Apache-2.0
# Simple profile class for installing the proper version of kubectl
# NOTE: Resist the urge to just old it in some other profile, it's been split
# off in its own profile so that it can be reused in e.g. deployment servers
class profile::kubernetes::client (
    K8s::KubernetesVersion $version = lookup('profile::kubernetes::client::version',),
) {
    # class { 'k8s::client':
    #     version => $version,
    # }
    # FIXME: This is a hack to support multiple versions of kubectl
    #        which I failed to do properly, see T388388
    k8s::package { 'kubectl':
        package => 'client',
        version => $version,
    }
    k8s::package { 'kubectl131':
        package => 'client',
        version => '1.31',
    }
}
