class k8s::controller(
    $use_package = false,
    $cluster_cidr = '192.168.0.0/24',
){
    include ::k8s::users

    if $use_package {
        require_package('kubernetes-master')
    } else {
        file { '/usr/bin/kube-controller-manager':
            ensure => link,
            target => '/usr/local/bin/kube-controller-manager',
        }
    }

    file { '/etc/default/kube-controller-manager':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('k8s/kube-controller-manager.default.erb'),
    }

    base::service_unit { 'kube-controller-manager':
        systemd => true,
    }
}
