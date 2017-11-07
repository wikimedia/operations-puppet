class k8s::infrastructure_config(
    $master_host,
    $username = 'client-infrastructure',
) {
    file { '/etc/kubernetes':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $users = hiera('k8s_infrastructure_users')
    file { '/etc/kubernetes/kubeconfig':
        ensure  => present,
        content => template('k8s/kubeconfig-client.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes'],
    }
}
