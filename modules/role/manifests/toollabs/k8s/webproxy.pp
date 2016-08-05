class role::toollabs::k8s::webproxy {

    $master_host = hiera('k8s_master')
    $etcd_url = join(prefix(suffix(hiera('flannel::etcd_hosts'), ':2379'), 'https://'), ',')

    ferm::service { 'flannel-vxlan':
        proto => udp,
        port  => 8472,
    }

    class { '::k8s::flannel':
        etcd_endpoints => $etcd_url,
    }

    class { '::toollabs::kube2proxy':
        master_host => $master_host,
    }

    class { 'k8s::proxy':
        master_host => $master_host,
    }

    # Deployment script (for now!)
    file { '/usr/local/bin/deploy-proxy':
        source => 'puppet:///modules/role/toollabs/deploy-proxy.bash',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }
}
