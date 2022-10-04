# SPDX-License-Identifier: Apache-2.0
#  Class that sets up and configures kube-scheduler
class k8s::scheduler (
    Stdlib::Unixpath $kubeconfig,
    Boolean $logtostderr = true,
    Integer $v_log_level = 0,
    Boolean $packages_from_future = false,
) {
    if $packages_from_future {
        if debian::codename::le('buster') {
            apt::package_from_component { 'scheduler-kubernetes-future':
                component => 'component/kubernetes-future',
                packages  => ['kubernetes-master'],
            }
        } else {
            apt::package_from_component { 'scheduler-kubernetes116':
                component => 'component/kubernetes116',
                packages  => ['kubernetes-master'],
            }
        }
    } else {
        ensure_packages('kubernetes-master')
    }

    file { '/etc/default/kube-scheduler':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('k8s/kube-scheduler.default.erb'),
        notify  => Service['kube-scheduler'],
    }

    service { 'kube-scheduler':
        ensure => running,
        enable => true,
    }
}
