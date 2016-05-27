class role::toollabs::k8s::worker {
    # NOTE: No base::firewall!
    # ferm and kube-proxy will conflict
    include toollabs::infrastructure

    $master_host = hiera('k8s::master_host')
    $etcd_url = join(prefix(suffix(hiera('flannel::etcd_hosts', [$master_host]), ':2379'), 'https://'), ',')

    ferm::service { 'flannel-vxlan':
        proto => udp,
        port  => 8472,
    }

    class { '::k8s::flannel':
        etcd_endpoints => $etcd_url,
    }

    labs_lvm::volume { 'docker-storage':
        mountat => '/var/lib/docker',
    }
    class { '::k8s::docker':
        require => [
            Class['::k8s::flannel'],
            Labs_lvm::Volume['docker-storage'],
        ]
    }
    class { '::k8s::ssl':
        provide_private => true,
        notify          => Class['k8s::kubelet'],
    }


    class { 'k8s::kubelet':
        master_host => $master_host,
        require     => Class['::k8s::docker'],
    }

    class { 'k8s::proxy':
        master_host => $master_host,
    }

    # Deployment script (for now!)
    file { '/usr/local/bin/deploy-worker':
        source => 'puppet:///modules/role/toollabs/deploy-worker.bash',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }
}
