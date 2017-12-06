class k8s::scheduler {

    require_package('kubernetes-master')

    file { '/etc/default/kube-scheduler':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('k8s/kube-scheduler.default.erb'),
    }

    service { 'kube-scheduler':
        ensure => running,
        enable => true,
    }
}
