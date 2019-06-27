class k8s::infrastructure_config(
    String $master_host,
    String $username = 'client-infrastructure',
) {
    file { '/etc/kubernetes':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $users = hiera('k8s_infrastructure_users')
    k8s::kubeconfig { '/etc/kubernetes/kubeconfig':
        master_host => $master_host,
        username    => $username,
        token       => $users[$username]['token'],
    }
}
