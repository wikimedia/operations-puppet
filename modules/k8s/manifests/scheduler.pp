# SPDX-License-Identifier: Apache-2.0
#  Class that sets up and configures kube-scheduler
class k8s::scheduler (
    K8s::KubernetesVersion $version,
    Stdlib::Unixpath $kubeconfig,
    Boolean $logtostderr = true,
    Integer $v_log_level = 0,
) {
    k8s::package { 'scheduler':
        package => 'master',
        version => $version,
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
