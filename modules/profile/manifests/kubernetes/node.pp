class profile::kubernetes::node {
    $master_host = hiera('profile::kubernetes::master_host')
    $infra_pod = hiera('profile::kubernetes::infra_pod')

    base::expose_puppet_certs { '/etc/kubernetes':
        provide_private => true,
    }

    # TODO: Need to set TLS
    class { '::k8s::kubelet':
        master_host               => $master_host,
        listen_address            => '0.0.0.0',
        use_package               => true,
        pod_infra_container_image => $infra_pod,
        cluster_domain            => $::site,
        tls_cert                  => '/etc/kubernetes/ssl/cert.pem',
        tls_key                   => '/etc/kubernetes/ssl/server.key',
    }

    class { 'k8s::proxy':
        master_host => $master_host,
    }
}
