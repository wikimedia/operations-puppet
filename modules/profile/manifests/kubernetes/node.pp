class profile::kubernetes::node(
  $master_fqdn = hiera('profile::kubernetes::master_fqdn'),
  $master_hosts = hiera('profile::kubernetes::master_hosts'),
  $infra_pod = hiera('profile::kubernetes::infra_pod'),
  $use_cni = hiera('profile::kubernetes::use_cni'),
  $masquerade_all = hiera('profile::kubernetes::node::masquerade_all', true),
  $username = hiera('profile::kubernetes::node::username', 'client-infrastructure'),
  ) {

    base::expose_puppet_certs { '/etc/kubernetes':
        provide_private => true,
        user            => 'root',
        group           => 'root',
    }

    class { '::k8s::infrastructure_config':
        master_host => $master_fqdn,
        username    => $username,
    }

    class { '::k8s::kubelet':
        master_host               => $master_fqdn,
        listen_address            => '0.0.0.0',
        cluster_dns_ip            => '192.168.0.100',
        cni                       => $use_cni,
        pod_infra_container_image => $infra_pod,
        cluster_domain            => undef,
        tls_cert                  => '/etc/kubernetes/ssl/cert.pem',
        tls_key                   => '/etc/kubernetes/ssl/server.key',
    }
    class { '::k8s::proxy':
        master_host    => $master_fqdn,
        masquerade_all => $masquerade_all,
    }

    $master_hosts_ferm = join($master_hosts, ' ')
    ferm::service { 'kubelet-http':
        proto  => 'tcp',
        port   => '10250',
        srange => "(@resolve((${master_hosts_ferm})))",
    }
}
