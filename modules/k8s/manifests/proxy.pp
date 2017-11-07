class k8s::proxy(
    $master_host,
    $proxy_mode = 'iptables',
    $masquerade_all = true,
) {
    require ::k8s::infrastructure_config

    $master_ip = ipresolve($master_host, 4, $::nameservers[0])

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
        subscribe => [
            File['/etc/kubernetes/kubeconfig'],
            File['/etc/default/kube-proxy'],
        ],

    }
}
