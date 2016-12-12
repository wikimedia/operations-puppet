class k8s::scheduler(
    $use_package = false,
) {
    include k8s::users

    if $use_package {
        require_package('kubernetes-master')
    } else {
        file { '/usr/local/bin/kube-scheduler':
            ensure => link,
            target => '/usr/bin/kube-scheduler',
        }
    }

    file { '/etc/default/kube-scheduler':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('k8s/kube-scheduler.default.erb'),
    }

    base::service_unit { 'kube-scheduler':
        systemd => true,
    }
}
