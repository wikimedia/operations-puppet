# filtertags: labs-project-tools
class role::toollabs::k8s::worker {
    # NOTE: No ::base::firewall!
    # ferm and kube-proxy will conflict
    include ::toollabs::infrastructure

    $master_host = hiera('k8s::master_host')
    $etcd_url = join(prefix(suffix(hiera('flannel::etcd_hosts', [$master_host]), ':2379'), 'https://'), ',')

    ferm::service { 'flannel-vxlan':
        proto => udp,
        port  => 8472,
    }

    class { '::k8s::flannel':
        etcd_endpoints => $etcd_url,
    }

    $docker_version = '1.11.2-0~jessie'

    class { '::profile::docker::storage':
        physical_volumes => '/dev/vda4',
        vg_to_remove     => 'vd',
    }

    class { '::profile::docker::engine':
        settings        => {
            'iptables' => false,
            'ip-masq'  => false,
        },
        version         => $docker_version,
        declare_service => false,
        require         => Class['::profile::docker::storage'],
    }

    class { '::profile::docker::flannel':
        docker_version => $docker_version,
        require        => Class['::profile::docker::engine'],
    }


    class { '::k8s::ssl':
        provide_private => true,
        notify          => Class['k8s::kubelet'],
    }

    class { '::k8s::kubelet':
        master_host => $master_host,
        require     => Class[::profile::docker::flannel],
        use_package => true,
    }

    class { '::k8s::proxy':
        master_host => $master_host,
        use_package => true,
    }
}
