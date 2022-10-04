class profile::kubernetes::master (
    String $kubernetes_cluster_group = lookup('profile::kubernetes::master::cluster_group'),
    Array[String] $etcd_urls=lookup('profile::kubernetes::master::etcd_urls'),
    # List of hosts this is accessible to.
    # SPECIAL VALUE: use 'all' to have this port be open to the world
    String $accessible_to=lookup('profile::kubernetes::master::accessible_to'),
    String $service_cluster_ip_range=lookup('profile::kubernetes::master::service_cluster_ip_range'),
    Optional[String] $service_node_port_range=lookup('profile::kubernetes::master::service_node_port_range', { 'default_value' => undef }),
    Integer $apiserver_count=lookup('profile::kubernetes::master::apiserver_count'),
    Optional[Stdlib::Fqdn] $service_cert=lookup('profile::kubernetes::master::service_cert', { 'default_value' => undef }),
    Boolean $use_cergen=lookup('profile::kubernetes::master::use_cergen', { default_value => false }),
    Stdlib::Unixpath $ssl_cert_path=lookup('profile::kubernetes::master::ssl_cert_path'),
    Stdlib::Unixpath $ssl_key_path=lookup('profile::kubernetes::master::ssl_key_path'),
    String $authz_mode=lookup('profile::kubernetes::master::authz_mode'),
    Optional[Stdlib::Unixpath] $service_account_private_key_file=lookup('profile::kubernetes::master::service_account_private_key_file', { 'default_value' => undef }),
    Stdlib::Httpurl $prometheus_url=lookup('profile::kubernetes::master::prometheus_url', { 'default_value' => "http://prometheus.svc.${::site}.wmnet/k8s" }),
    Optional[String] $runtime_config=lookup('profile::kubernetes::master::runtime_config', { 'default_value' => undef }),
    Boolean $packages_from_future = lookup('profile::kubernetes::master::packages_from_future', { default_value => false }),
    Boolean $allow_privileged = lookup('profile::kubernetes::master::allow_privileged', { default_value => false }),
    String $controllermanager_token = lookup('profile::kubernetes::master::controllermanager_token'),
    String $scheduler_token = lookup('profile::kubernetes::master::scheduler_token'),
    Hash[String, Profile::Kubernetes::User_tokens] $all_infrastructure_users = lookup('profile::kubernetes::infrastructure_users'),
    Optional[K8s::AdmissionPlugins] $admission_plugins = lookup('profile::kubernetes::master::admission_plugins', { default_value => undef }),
    Optional[Array[Hash]] $admission_configuration = lookup('profile::kubernetes::master::admission_configuration', { default_value => undef })

) {
    if $service_cert {
        sslcert::certificate { $service_cert:
            ensure       => present,
            group        => 'kube',
            skip_private => false,
            use_cergen   => $use_cergen,
        }
    }

    $etcd_servers = join($etcd_urls, ',')
    # Get the local users and the corresponding tokens.
    $_tokens = $all_infrastructure_users[$kubernetes_cluster_group].filter |$_,$data| {
        # If "constrain_to" is defined, restrict the user to the masters that meet the regexp
        $data['constrain_to'] ? {
            undef => true,
            default => ($facts['fqdn'] =~ Regexp($data['constrain_to']))
        }
    }

    class { 'k8s::apiserver':
        etcd_servers             => $etcd_servers,
        ssl_cert_path            => $ssl_cert_path,
        ssl_key_path             => $ssl_key_path,
        users                    => $_tokens,
        authz_mode               => $authz_mode,
        allow_privileged         => $allow_privileged,
        packages_from_future     => $packages_from_future,
        service_cluster_ip_range => $service_cluster_ip_range,
        service_node_port_range  => $service_node_port_range,
        apiserver_count          => $apiserver_count,
        runtime_config           => $runtime_config,
        admission_plugins        => $admission_plugins,
        admission_configuration  => $admission_configuration,
    }

    $scheduler_kubeconfig = '/etc/kubernetes/scheduler_config'
    # $service_cert holds the FQDN for the load balanced API
    k8s::kubeconfig { $scheduler_kubeconfig:
        master_host => $service_cert,
        username    => 'system:kube-scheduler',
        token       => $scheduler_token,
        owner       => 'kube',
        group       => 'kube',
    }
    class { 'k8s::scheduler':
        packages_from_future => $packages_from_future,
        kubeconfig           => $scheduler_kubeconfig,
    }

    $controllermanager_kubeconfig = '/etc/kubernetes/controller-manager_config'
    # $service_cert holds the FQDN for the load balanced API
    k8s::kubeconfig { $controllermanager_kubeconfig:
        master_host => $service_cert,
        username    => 'system:kube-controller-manager',
        token       => $controllermanager_token,
        owner       => 'kube',
        group       => 'kube',
    }
    class { 'k8s::controller':
        service_account_private_key_file => $service_account_private_key_file,
        kubeconfig                       => $controllermanager_kubeconfig,
        packages_from_future             => $packages_from_future,
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
}
