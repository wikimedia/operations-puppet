class k8s::kubelet(
    $master_host,
    $cluster_dns_ip = '192.168.0.100',
) {
    include ::k8s::infrastructure_config
    require_package('kubelet')

    file { [
        '/etc/kubernetes/',
        '/etc/kubernetes/manifests',
    ]:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { [
        '/var/run/kubernetes',
        '/var/lib/kubelet',
    ] :
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0700',
    }

    class { '::k8s::ssl':
        provide_private => true,
        notify          => Base::Service_unit['kubelet'],
    }

    base::service_unit { 'kubelet':
        systemd   => true,
        subscribe => File['/etc/kubernetes/kubeconfig'],
    }
}
