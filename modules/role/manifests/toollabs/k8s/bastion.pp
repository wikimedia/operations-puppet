# filtertags: labs-project-tools
class role::toollabs::k8s::bastion {

    $master_host = hiera('k8s::master_host')
    $etcd_url = join(prefix(suffix(hiera('flannel::etcd_hosts', [$master_host]), ':2379'), 'https://'), ',')

    ferm::service { 'flannel-vxlan':
        proto => udp,
        port  => 8472,
    }

    class { '::k8s::flannel':
        etcd_endpoints => $etcd_url,
    }

    class { '::k8s::proxy':
        master_host => $master_host,
    }

    require_package('kubernetes-client')
}
