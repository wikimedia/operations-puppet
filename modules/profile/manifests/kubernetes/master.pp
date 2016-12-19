class profile::kubernetes::master(
    $etcd_urls=hiera('profile::kubernetes::master::etcd_urls'),
    $docker_registry=hiera('profile::kubernetes::master::docker_registry'),
){
    base::expose_puppet_certs { '/etc/kubernetes':
        provide_private => true,
        user            => 'kubernetes',
        group           => 'kubernetes',
    }
    $etcd_servers = join($etcd_urls, ',')
    class { '::k8s::apiserver':
        etcd_servers         => $etcd_servers,
        docker_registry      => $docker_registry,
        ssl_cert_path        => '/etc/kubernetes/ssl/cert.pem',
        ssl_key_path         => '/etc/kubernetes/ssl/server.key',
        ssl_certificate_name => '',
    }

    class { '::k8s::scheduler': }
    class { '::k8s::controller': }

    ferm::service { 'apiserver-https':
        proto  => 'tcp',
        port   => '6443',
        srange => '$DOMAIN_NETWORKS',
    }

    diamond::collector { 'Kubernetes':
        source => 'puppet:///modules/diamond/collector/kubernetes.py',
    }
}
