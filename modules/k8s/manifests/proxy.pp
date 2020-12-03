# Class that sets up and configures kube-proxy
class k8s::proxy(
    String $kubeconfig,
    Boolean $masquerade_all,
    String $proxy_mode = 'iptables',
    Boolean $logtostderr = true,
    Integer $v_log_level = 0,
    Boolean $packages_from_future = false,
    Optional[String] $metrics_bind_address = undef,
) {
    if $packages_from_future {
        apt::package_from_component { 'proxy-kubernetes-future':
            component => 'component/kubernetes-future',
            packages  => ['kubernetes-node'],
        }
    } else {
        require_package('kubernetes-node')
    }

    file { '/etc/default/kube-proxy':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('k8s/kube-proxy.default.erb'),
        notify  => Service['kube-proxy'],
    }

    service { 'kube-proxy':
        ensure    => running,
        enable    => true,
        subscribe => [
            File[$kubeconfig],
            File['/etc/default/kube-proxy'],
        ],

    }
}
