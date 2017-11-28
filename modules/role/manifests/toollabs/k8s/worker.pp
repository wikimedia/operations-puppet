# filtertags: labs-project-tools
class role::toollabs::k8s::worker {
    include ::toollabs::infrastructure

    $flannel_etcd_url = join(prefix(suffix(hiera('flannel::etcd_hosts'), ':2379'), 'https://'), ',')

    ferm::service { 'flannel-vxlan':
        proto => udp,
        port  => 8472,
    }

    class { '::k8s::flannel':
        etcd_endpoints => $flannel_etcd_url,
    }

    $docker_version = '1.12.6-0~debian-jessie'

    class { '::profile::docker::storage':
        physical_volumes => '/dev/vda4',
        vg_to_remove     => 'vd',
    }

    class { '::profile::docker::engine':
        settings        => {
            'iptables'     => false,
            'ip-masq'      => false,
            'live-restore' => true,
        },
        version         => $docker_version,
        declare_service => false,
        require         => Class['::profile::docker::storage'],
    }

    class { '::profile::docker::flannel':
        docker_version => $docker_version,
        require        => Class['::profile::docker::engine'],
    }


    class { '::profile::kubernetes::node':
        use_cni   => false,
        infra_pod => 'docker-registry.tools.wmflabs.org/pause:2.0',
        require   => Class[::profile::docker::flannel],
    }
}
