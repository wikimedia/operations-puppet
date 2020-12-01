#  Class that sets up and configures kube-scheduler
class k8s::scheduler(
    Boolean $logtostderr = true,
    Integer $v_log_level = 0,
    Boolean $packages_from_future = false,
    Optional[String] $kubeconfig = undef,
) {

    if $packages_from_future {
        apt::package_from_component { 'scheduler-kubernetes-future':
            component => 'component/kubernetes-future',
            packages  => ['kubernetes-master'],
        }
    } else {
        require_package('kubernetes-master')
    }

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
