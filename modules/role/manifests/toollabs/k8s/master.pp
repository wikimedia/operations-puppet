# filtertags: labs-project-tools
class role::toollabs::k8s::master {
    include base::firewall
    include ::toollabs::infrastructure

    $master_host = hiera('k8s::master_host', $::fqdn)
    $etcd_url = join(prefix(suffix(hiera('k8s::etcd_hosts'), ':2379'), 'https://'), ',')

    sslcert::certificate { 'star.tools.wmflabs.org':
        before       => Class['::k8s::apiserver'],
    }

    class { '::k8s::apiserver':
        etcd_servers               => $etcd_url,
        docker_registry            => hiera('docker::registry'),
        host_automounts            => [
            '/var/run/nslcd/socket',
            '/etc/ldap.yaml',
        ],
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

    diamond::collector { 'Kubernetes':
        source => 'puppet:///modules/diamond/collector/kubernetes.py',
    }
}
