define k8s::kubeconfig(
    $master_host,
    $username,
    $token,
    $mode='0400',
    $owner='root',
    $group='root',
) {
    file { $title:
        ensure  => present,
        content => template('k8s/kubeconfig-client.yaml.erb'),
        owner   => $owner,
        group   => $group,
        mode    => $mode,
        require => File['/etc/kubernetes'],
    }
}
