class role::toollabs::k8s::master {
    include base::firewall
    include toollabs::infrastructure

    include ::etcd

    $master_host = hiera('k8s::master_host', $::fqdn)
    $etcd_url = join(prefix(suffix(hiera('k8s::etcd_hosts'), ':2379'), 'https://'), ',')

    class { 'k8s::apiserver':
        master_host  => $master_host,
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

    # Deployment script (for now!)
    file { '/usr/local/bin/deploy-master':
        source => 'file:///modules/role/toollabs/deploy-master.bash',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }
}
