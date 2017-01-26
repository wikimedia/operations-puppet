class profile::kubernetes::node {
    $master_hosts = hiera('profile::kubernetes::master_hosts')
    $infra_pod = hiera('profile::kubernetes::infra_pod')

    base::expose_puppet_certs { '/etc/kubernetes':
        provide_private => true,
        user            => 'root',
        group           => 'root',
    }
    # TODO: Evaluate whether it makes sense to use a naive per host balancing
    # based on fqdn_rand() here or whether a more HA solution is better
    $master_host = $master_hosts[0]
    class { '::k8s::kubelet':
        master_host               => $master_host,
        listen_address            => '0.0.0.0',
        cluster_dns_ip            => '192.168.0.100',
        use_package               => true,
        cni                       => true,
        pod_infra_container_image => $infra_pod,
        cluster_domain            => undef,
        tls_cert                  => '/etc/kubernetes/ssl/cert.pem',
        tls_key                   => '/etc/kubernetes/ssl/server.key',
    }
    class { '::k8s::proxy':
        master_host => $master_host,
        use_package => true,
    }

    $master_hosts_ferm = join($master_hosts, ' ')
    ferm::service { 'kubelet-http':
        proto  => 'tcp',
        port   => '10250',
        srange => "(@resolve((${master_hosts_ferm})))",
    }
}
