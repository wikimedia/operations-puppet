class k8s::kubelet(
    $master_host,
    $cluster_dns_ip = '192.168.0.100',
) {
    require_package('kubelet')

    file { [
        '/etc/kubernetes/',
        '/etc/kubernetes/manifests',
    ]:
        ensure => directory,
        owner  => 'kubernetes',
        group  => 'kubernetes',
        mode   => '0755',
    }

    file { '/etc/kubernetes/kubeconfig':
        ensure  => present,
        content => template('k8s/kubeconfig-client.yaml.erb'),
        owner   => 'kubernetes',
        group   => 'kubernetes',
        mode    => '0400',
        notify  => Base::Service_unit['kubelet'],
    }

    file { [
        '/var/run/kubernetes',
        '/var/lib/kubelet',
    ] :
        ensure => directory,
        owner  => 'kubernetes',
        group  => 'kubernetes',
        mode   => '0700',
    }

    include k8s::users

    class { '::k8s::ssl':
        notify  => Base::Service_unit['kubelet'],
    }

    base::service_unit { 'kubelet':
        systemd => true,
    }
}
