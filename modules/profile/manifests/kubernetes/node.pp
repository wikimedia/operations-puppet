class profile::kubernetes::node {
    $master_host = hiera('profile::kubernetes::master_host')
    $infra_pod = hiera('profile::kubernetes::infra_pod')

    # TODO: Need to set TLS
    class { '::k8s::kubelet':
        master_host               => $master_host,
        listen_address            => '0.0.0.0',
        cluster_dns_ip            => '192.168.0.100',
        use_package               => true,
        pod_infra_container_image => $infra_pod,
        cluster_domain            => undef,
        tls_cert                  => undef,
        tls_key                   => undef,
    }
    class { 'k8s::proxy':
        master_host => $master_host,
    }
}
