define k8s::kubeconfig(
    String $master_host,
    String $username,
    String $token,
    Optional[String] $namespace=undef,
    Stdlib::Filemode $mode='0400',
    String $owner='root',
    String $group='root',
) {
    require k8s::base_dirs
    file { $title:
        ensure  => present,
        content => template('k8s/kubeconfig-client.yaml.erb'),
        owner   => $owner,
        group   => $group,
        mode    => $mode,
    }
}
