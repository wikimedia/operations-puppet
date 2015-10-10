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
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $users = hiera('k8s_users')
    # Ugly HACK!
    $client_token = inline_template("<%= @users.select { |u| u['name'] == 'client-infrastructure' }[0]['token'] %>")
    file { '/etc/kubernetes/kubeconfig':
        ensure  => present,
        content => template('k8s/kubeconfig-client.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        notify  => Base::Service_unit['kubelet'],
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
        systemd => true,
    }
}
