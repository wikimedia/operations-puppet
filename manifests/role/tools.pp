# Roles for Kubernetes and co on Tool Labs
class role::toollabs::etcd {
    # To deny access to etcd - atm the kubernetes master
    # and etcd will be on the same host, so ok to just deny
    # access to everyone else
    include base::firewall
    include toollabs::infrastructure

    include etcd
}

class role::toollabs::k8s::master {
    # This requires that etcd is on the same host
    # And is not HA. Will re-evaluate when it is HA

    include base::firewall
    include toollabs::infrastructure

    include role::toollabs::etcd

    $master_host = hiera('k8s_master', $::fqdn)
    $etcd_url = join(prefix(suffix(hiera('etcd_hosts', [$::fqdn]), ':2379'), 'https://')',')

    class { 'k8s::apiserver':
        master_host => $master_host,
        etcd_servers => $etcd_url,

    }
    class { 'k8s::scheduler':
        master_host => $master_host,
    }

    class { 'k8s::controller':
        master_host => $master_host,
    }
}
