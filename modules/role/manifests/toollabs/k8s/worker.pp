# filtertags: labs-project-tools
class role::toollabs::k8s::worker {
    # NOTE: No base::firewall!
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

    class {'::profile::docker::storage':
        vg_to_remove     => 'vd',
        physical_volumes => '/dev/vda4',
    }

    class { '::profile::docker::engine':
        settings => {
            'iptables' => false,
            'ip-masq'  => false,
        },
        version  => '1.11.2-0~jessie',
        require  => Class['::profile::docker::storage'],
    }

    class { '::k8s::ssl':
        provide_private => true,
        notify          => Class['k8s::kubelet'],
    }

    class { '::k8s::kubelet':
        master_host => $master_host,
        require     => Class['::k8s::docker'],
        use_package => true,
    }

    class { '::k8s::proxy':
        master_host => $master_host,
        use_package => true,
    }
}
