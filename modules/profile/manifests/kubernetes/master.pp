class profile::kubernetes::master(
    $master_host=hiera('profile::kubernetes::master_host'),
    $etcd_urls=hiera('profile::kubernetes::master::etcd_urls'),
    $infra_pod=hiera('profile::kubernetes::master::infra_pod'),
    $docker_registry=hiera('profile::kubernetes::master::docker_registry'),
){
    $etcd_servers = join($etcd_urls, ',')
    # TODO: Need TLS
    class { '::k8s::apiserver':
        etcd_servers    => $etcd_servers,
        docker_registry => $docker_registry,
    }

    class { '::k8s::scheduler': }
    class { '::k8s::controller': }

    ferm::service { 'apiserver-https':
        proto => 'tcp',
        port  => '6443',
        srage => '$DOMAIN_NETWORKS',
    }

    diamond::collector { 'Kubernetes':
        source => 'puppet:///modules/diamond/collector/kubernetes.py',
    }
}
