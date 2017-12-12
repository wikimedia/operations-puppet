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

    # Firewall!  Kubelet opens some scary ports to the outside world, 
    #  so this class just closes those particular ports whilst leaving everything
    #  else in the hands of the OpenStack security groups.
    $master_hosts = hiera('k8s::master_hosts')
    $master_hosts_ferm = join($master_hosts, ' ')

    ferm::service { 'kubelet-http':
        proto  => 'tcp',
        port   => '10250',
        srange => "@resolve((${master_hosts_ferm}))",
    }
    ferm::service { 'kubelet-http-readonly-prometheus':
        proto  => 'tcp',
        port   => '10255',
        srange => "@resolve((${master_hosts_ferm}))",
    }

    ferm::service { 'flannel-vxlan':
        proto => udp,
        port  => 8472,
    }

    # We really only want to be this permissive for other tools hosts.
    #  Fortunately there's a nova-network security rule overlaying this
    #  one which limits this permissive policy to things within the tools
    #  project.
    #
    # Ideally this will get winnowed down as time passes, but for the
    #  moment I just really want to get the above things properly closed off
    ferm::rule {'rest-of-everything':
        rule => "saddr 10.0.0.0/8 proto tcp dport (1:8472, 8473:10249, 10251:10254, 10256:65535) ACCEPT;"
    }

    include profile::base::firewall
}
