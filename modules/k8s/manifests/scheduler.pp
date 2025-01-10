# SPDX-License-Identifier: Apache-2.0
#  Class that sets up and configures kube-scheduler
class k8s::scheduler (
    K8s::KubernetesVersion $version,
    Stdlib::Unixpath $kubeconfig,
    Stdlib::Unixpath $tls_cert_file,
    Stdlib::Unixpath $tls_private_key_file,
    Integer $v_log_level = 0,
) {
    k8s::package { 'scheduler':
        package => 'master',
        version => $version,
    }

    # Create the KubeSchedulerConfiguration YAML
    # API version v1beta3 is deprecated since 1.26 and removed in 1.29
    if versioncmp($version, '1.26') > 0 {
        $api_version = 'kubescheduler.config.k8s.io/v1'
    } else {
        $api_version = 'kubescheduler.config.k8s.io/v1beta3'
    }
    $config_yaml = {
        apiVersion         => $api_version,
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
        require => K8s::Package['scheduler'],
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
        ensure    => running,
        enable    => true,
        subscribe => [
            File[$kubeconfig],
        ],
    }
}
