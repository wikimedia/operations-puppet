class k8s::controller(
    Optional[String] $service_account_private_key_file=undef,
){

    require_package('kubernetes-master')

    file { '/etc/default/kube-controller-manager':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('k8s/kube-controller-manager.default.erb'),
        notify  => Service['kube-controller-manager'],
    }

    service { 'kube-controller-manager':
        ensure => running,
        enable => true,
    }
}
