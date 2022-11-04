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

    # Create the KubeSchedulerConfiguration YAML
    $config_yaml = {
        apiVersion         => versioncmp($version, '1.16') <= 0 ? {
            true  => 'kubescheduler.config.k8s.io/v1alpha1',
            false => 'kubescheduler.config.k8s.io/v1beta3',
        },
        kind               => 'KubeSchedulerConfiguration',
        clientConnection   => { kubeconfig => $kubeconfig },
    }
    $config_file = '/etc/kubernetes/kube-scheduler-config.yaml'
    file { $config_file:
        ensure  => file,
        owner   => 'kube',
        group   => 'kube',
        mode    => '0400',
        content => $config_yaml.filter |$k, $v| { $v =~ NotUndef and !$v.empty }.to_yaml,
        notify  => Service['kube-scheduler'],
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
