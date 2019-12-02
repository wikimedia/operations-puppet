class profile::toolforge::k8s::webproxy (
    $k8s_infrastructure_users   = lookup('k8s_infrastructure_users'), # complex datatype?
    Stdlib::Fqdn  $master_host  = lookup('k8s_master'),
    Array[String] $etcd_hosts   = lookup('flannel::etcd_hosts'),
    String        $active_proxy = lookup('profile::toolforge::active_proxy_host', {default_value => 'tools-proxy-03'})
) {
    # workaround kube-proxy not playing well with iptables-nft
    if os_version('debian == buster') {
        alternatives::select { 'iptables':
            path    => '/usr/sbin/iptables-legacy',
        }
    }

    $etcd_url = join(prefix(suffix($etcd_hosts, ':2379'), 'https://'), ',')

    ferm::service { 'flannel-vxlan':
        proto => udp,
        port  => 8472,
    }

    class { '::k8s::flannel':
        etcd_endpoints => $etcd_url,
    }

    class { '::toolforge::kube2proxy':
        k8s_infrastructure_users => $k8s_infrastructure_users,
        master_host              => $master_host,
        active_proxy_host        => $active_proxy,
    }

    class { '::k8s::infrastructure_config':
        master_host => $master_host,
    }

    class { '::k8s::proxy':
        master_host          => $master_host,
        metrics_bind_address => undef,
    }

    # The kubelet service is installed automatically as part of the kubernetes-node
    # deb, we don't want it to be running on tools-proxy - so we are explicitly ensuring
    # it's stopped
    service { 'kubelet':
        ensure => stopped,
    }
}
