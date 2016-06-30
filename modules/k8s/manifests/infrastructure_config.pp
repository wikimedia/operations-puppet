class k8s::infrastructure_config {
    file { '/etc/kubernetes':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $users = hiera('k8s_infrastructure_users')
    # Ugly HACK!
    $client_token = inline_template("<%= @users.select { |u| u['name'] == 'client-infrastructure' }[0]['token'] %>")
    file { '/etc/kubernetes/kubeconfig':
        ensure  => present,
        content => template('k8s/kubeconfig-client.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes'],
    }
}
