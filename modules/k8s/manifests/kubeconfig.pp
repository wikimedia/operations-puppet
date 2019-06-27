define k8s::kubeconfig(
    String $master_host,
    String $username,
    String $token,
    Optional[String] $namespace=undef,
    String $mode='0400',
    String $owner='root',
    String $group='root',
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
