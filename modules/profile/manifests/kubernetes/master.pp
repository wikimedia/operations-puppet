class profile::kubernetes::master(
    $etcd_urls=hiera('profile::kubernetes::master::etcd_urls'),
    # List of hosts this is accessible to.
    # SPECIAL VALUE: use 'all' to have this port be open to the world
    $accessible_to=hiera('profile::kubernetes::master::accessible_to'),
    $service_cluster_ip_range=hiera('profile::kubernetes::master::service_cluster_ip_range'),
    $service_node_port_range=hiera('profile::kubernetes::master::service_node_port_range', undef),
    $apiserver_count=hiera('profile::kubernetes::master::apiserver_count'),
    $storage_backend=hiera('profile::kubernetes::master::storage_backend', 'etcd2'),
    $admission_controllers=hiera('profile::kubernetes::master::admission_controllers'),
    $expose_puppet_certs=hiera('profile::kubernetes::master::expose_puppet_certs'),
    $service_cert=hiera('profile::kubernetes::master::service_cert', undef),
    $ssl_cert_path=hiera('profile::kubernetes::master::ssl_cert_path'),
    $ssl_key_path=hiera('profile::kubernetes::master::ssl_cert_path'),
    $authz_mode=hiera('profile::kubernetes::master::authz_mode'),
    $service_account_private_key_file=hiera('profile::kubernetes::master::service_account_private_key_file', undef),
    $prometheus_url=hiera('profile::kubernetes::master::prometheus_url', "http://prometheus.svc.${::site}.wmnet/k8s"),
    $runtime_config=hiera('profile::kubernetes::master::runtime_config', undef),
){
    if $expose_puppet_certs {
        base::expose_puppet_certs { '/etc/kubernetes':
            provide_private => true,
            user            => 'kube',
            group           => 'kube',
        }
    }

    if $service_cert {
        sslcert::certificate { $service_cert:
            ensure       => present,
            group        => 'kube',
            skip_private => false,
            before       => Class['::k8s::apiserver'],
        }
    }

    $etcd_servers = join($etcd_urls, ',')
    class { '::k8s::apiserver':
        etcd_servers             => $etcd_servers,
        ssl_cert_path            => $ssl_cert_path,
        ssl_key_path             => $ssl_key_path,
        authz_mode               => $authz_mode,
        storage_backend          => $storage_backend,
        service_cluster_ip_range => $service_cluster_ip_range,
        service_node_port_range  => $service_node_port_range,
        apiserver_count          => $apiserver_count,
        admission_controllers    => $admission_controllers,
        runtime_config           => $runtime_config,
    }

    class { '::k8s::scheduler': }
    class { '::k8s::controller':
        service_account_private_key_file => $service_account_private_key_file,
    }


    if $accessible_to == 'all' {
        $accessible_range = undef
    } else {
        $accessible_to_ferm = join($accessible_to, ' ')
        $accessible_range = "(@resolve((${accessible_to_ferm})) @resolve((${accessible_to_ferm}), AAAA))"
    }

    ferm::service { 'apiserver-https':
        proto  => 'tcp',
        port   => '6443',
        srange => $accessible_range,
    }

    # Alert us if API requests exceed a certain threshold. TODO: reevaluate
    # after we 've ran a few services
    monitoring::check_prometheus { 'apiserver_request_count':
        description     => 'Request count to the API',
        query           => "scalar(sum(rate(apiserver_request_count{instance=\"${::ipaddress}:6443\"}[5m])))",
        prometheus_url  => $prometheus_url,
        warning         => 50,
        critical        => 100,
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/kubernetes-api'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Kubernetes',
    }
    # Alert us if API requests latencies exceed a certain threshold. TODO: reevaluate
    # thresholds
    monitoring::check_prometheus { 'apiserver_request_latencies':
        description     => 'Request latencies',
        query           => "instance_verb:apiserver_request_latencies_summary:avg5m{verb\\!~\"(CONNECT|WATCH|WATCHLIST)\",instance=\"${::ipaddress}:6443\"}",
        prometheus_url  => $prometheus_url,
        nan_ok          => true,
        warning         => 50000,
        critical        => 100000,
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/kubernetes-api'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Kubernetes',
    }
    # Alert us if etcd requests latencies exceed a certain threshold. TODO: reevaluate
    # thresholds
    monitoring::check_prometheus { 'etcd_request_latencies':
        description     => 'etcd request latencies',
        query           => "instance_operation:etcd_request_latencies_summary:avg5m{instance=\"${::ipaddress}:6443\"}",
        prometheus_url  => $prometheus_url,
        nan_ok          => true,
        warning         => 30000,
        critical        => 50000,
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/kubernetes-api'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Etcd/Main_cluster',
    }
}
