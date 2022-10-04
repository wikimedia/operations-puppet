# SPDX-License-Identifier: Apache-2.0
# Class that sets up and configures kube-controller-manager
#
# The kubeconfig given should granted rights to the core role system:kube-controller-manager
# to permit kube-controller-manager to create service dedicated service accounts for all the
# controllers. See:
# https://v1-16.docs.kubernetes.io/docs/reference/access-authn-authz/rbac/#controller-roles
#
# Also make sure, that the kube-controller-manager uses the secure API port, rather than
# the privileged local one to not be able to bypass authentication and authorization checks.
#
# Note: This has the drawback that the kube-controller-manager will no longer talk to the local
#       apiserver, but to the LVS service instead (to be able to verify TLS cert).
class k8s::controller (
    String $service_account_private_key_file,
    Stdlib::Unixpath $kubeconfig,
    Boolean $logtostderr=true,
    Integer $v_log_level=0,
    Boolean $packages_from_future = false,
) {
    if $packages_from_future {
        if debian::codename::le('buster') {
            apt::package_from_component { 'controller-kubernetes-future':
                component => 'component/kubernetes-future',
                packages  => ['kubernetes-master'],
            }
        } else {
            apt::package_from_component { 'controller-kubernetes116':
                component => 'component/kubernetes116',
                packages  => ['kubernetes-master'],
            }
        }
    } else {
        ensure_packages('kubernetes-master')
    }

    file { '/etc/default/kube-controller-manager':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('k8s/kube-controller-manager.default.erb'),
        notify  => Service['kube-controller-manager'],
    }

    service { 'kube-controller-manager':
        ensure => running,
        enable => true,
    }
}
