class role::toollabs::k8s::master {
    include base::firewall
    include toollabs::infrastructure

    include ::etcd

    $master_host = hiera('k8s::master_host', $::fqdn)
    $etcd_url = join(prefix(suffix(hiera('k8s::etcd_hosts'), ':2379'), 'https://'), ',')

    sslcert::certificate { 'star.tools.wmflabs.org':
        skip_private => true,
        before       => Class['::k8s::apiserver'],
    }

    class { '::k8s::apiserver':
        master_host                => $master_host,
        etcd_servers               => $etcd_url,
        docker_registry            => hiera('docker::registry'),
        host_automounts            => ['/var/run/nslcd/socket'],
        ssl_certificate_name       => 'star.tools.wmflabs.org',
        host_path_prefixes_allowed => [
            '/data/project/',
            '/data/scratch/',
            '/public/dumps/',
        ],
    }

    class { '::toollabs::maintain_kubeusers':
        k8s_master => $master_host,
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
        source => 'puppet:///modules/role/toollabs/deploy-master.bash',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }
}
