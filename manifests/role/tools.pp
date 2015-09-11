# Roles for Kubernetes and co on Tool Labs
class role::toollabs::etcd {
    # To deny access to etcd - atm the kubernetes master
    # and etcd will be on the same host, so ok to just deny
    # access to everyone else
    include base::firewall
    include toollabs::infrastructure

    include etcd

    ferm::service{'etcd-clients':
        proto  => 'tcp',
        port   => hiera('etcd::client_port', '2379'),
    }
}

class role::toollabs::k8s::master {
    # This requires that etcd is on the same host
    # And is not HA. Will re-evaluate when it is HA

    include base::firewall
    include toollabs::infrastructure

    include role::toollabs::etcd

    $master_host = hiera('k8s_master', $::fqdn)
    $etcd_url = join(prefix(suffix(hiera('etcd_hosts', [$::fqdn]), ':2379'), 'https://'), ',')

    class { 'k8s::apiserver':
        master_host => $master_host,
        etcd_servers => $etcd_url,

    }
    class { 'k8s::scheduler': }

    class { 'k8s::controller': }

    # FIXME: Setup TLS properly, disallow HTTP
    ferm::service { 'apiserver-http':
        proto => 'tcp',
        port  => '8080',
    }

    ferm::service { 'apiserver-https':
        proto => 'tcp',
        port  => '6443',
    }
}

class role::toollabs::k8s::worker {
    # NOTE: No base::firewall!
    # ferm and kube-proxy will conflict

    include toollabs::infrastructure
    require k8s::docker

    $master_host = hiera('k8s_master')
    $etcd_url = join(prefix(suffix(hiera('etcd_hosts', [$master_host]), ':2379'), 'https://'), ',')

    class { '::k8s::flannel':
        etcd_endpoints => $etcd_url,
    }

    class { 'k8s::proxy':
        master_host => $master_host,
    }

    class { 'k8s::kubelet':
        master_host => $master_host,
    }
}
