class k8s::proxy(
    $master_host,
    $proxy_mode = 'iptables',
    $masquerade_all = true,
    $kubeconfig = '/etc/kubernetes/kubeconfig',
) {
    require ::k8s::infrastructure_config

    require_package('kubernetes-node')

    file { '/etc/default/kube-proxy':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('k8s/kube-proxy.default.erb'),
        notify  => Service['kube-proxy'],
    }


    if os_version('ubuntu <= trusty') {
      # Split this out into two, since we want to use the systemd unit
      # file from the deb but from puppet on upstart
      base::service_unit { 'kube-proxy':
          upstart         => upstart_template('kube-proxy'),
          declare_service => false,
      }
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
