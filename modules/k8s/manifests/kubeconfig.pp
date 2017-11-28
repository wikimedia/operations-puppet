define k8s::kubeconfig(
    $master_host,
    $username,
    $token,
) {
    file { $title:
        ensure  => present,
        content => template('k8s/kubeconfig-client.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes'],
    }
}
