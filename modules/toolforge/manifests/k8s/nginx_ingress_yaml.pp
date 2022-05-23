# SPDX-License-Identifier: Apache-2.0
class toolforge::k8s::nginx_ingress_yaml () {
    # Now served from a separate gitlab repository and deployed using the
    # wmcs.toolforge.k8s.component.deploy cookbook.
    # https://gitlab.wikimedia.org/repos/cloud/toolforge/ingress-nginx
    file { '/etc/kubernetes/nginx-ingress-helm-values.yaml':
        ensure => absent,
    }
}
