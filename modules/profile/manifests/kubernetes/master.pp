# SPDX-License-Identifier: Apache-2.0
# @summary
#   This class sets up a kubernetes master (apiserver)
#
class profile::kubernetes::master (
    String $kubernetes_cluster_name                                          = lookup('profile::kubernetes::cluster_name'),
    Hash[String, Profile::Kubernetes::User_tokens] $all_infrastructure_users = lookup('profile::kubernetes::infrastructure_users'),

    # TODO: Remove service_cert after T329826 is resolved
    Stdlib::Fqdn $service_cert                                               = lookup('profile::kubernetes::master::service_cert'),
    # TODO: Remove ssl_cert_path after T329826 is resolved
    Stdlib::Unixpath $ssl_cert_path                                          = lookup('profile::kubernetes::master::ssl_cert_path'),
    # TODO: Remove ssl_key_path after T329826 is resolved
    Stdlib::Unixpath $ssl_key_path                                           = lookup('profile::kubernetes::master::ssl_key_path'),
) {
    $kubernetes_cluster_config = k8s::fetch_cluster_config($kubernetes_cluster_name)
    $kubernetes_cluster_group = $kubernetes_cluster_config['cluster_group']
    $pki_intermediate_base = $kubernetes_cluster_config['pki_intermediate_base']
    $pki_renew_seconds = $kubernetes_cluster_config['pki_renew_seconds']
    $master_fqdn = $kubernetes_cluster_config['master']
    $master_url = $kubernetes_cluster_config['master_url']
    $version = $kubernetes_cluster_config['version']
    $etcd_urls = $kubernetes_cluster_config['etcd_urls']
    $service_node_port_range = $kubernetes_cluster_config['service_node_port_range']
    $ipv6dualstack = $kubernetes_cluster_config['ipv6dualstack']
    $admission_plugins = $kubernetes_cluster_config['admission_plugins']
    $admission_configuration = $kubernetes_cluster_config['admission_configuration']
    $service_cluster_cidr = $kubernetes_cluster_config['service_cluster_cidr']

    # Install kubectl matching the masters kubernetes version
    # (that's why we don't use profile::kubernetes::client)
    class { 'k8s::client':
        version => $version,
    }

    # FIXME: This should be removed after T329826 is resolved
    sslcert::certificate { $service_cert:
        ensure       => present,
        group        => 'kube',
        skip_private => false,
        use_cergen   => true,
    }
    # FIXME: With k8s 1.23 we still need this one (shared) cergen cert
    # for service-account token signing, see:
    # https://phabricator.wikimedia.org/T329826
    $cergen_sa_cert = {
        'chained' => $ssl_cert_path,
        'chain'   => '/nonexistent',
        'cert'    => $ssl_cert_path,
        'key'     => $ssl_key_path,
    }

    # The first useable IPv4 IP of the service cluster-cidr is automatically used as ClusterIP for the internal
    # kubernetes apiserver service (kubernetes.default.cluster.local)
    $apiserver_clusterip = wmflib::cidr_first_address($service_cluster_cidr['v4'])
    $apiserver_cert = profile::pki::get_cert($pki_intermediate_base, 'kube-apiserver', {
        'profile'        => 'server',
        'renew_seconds'  => $pki_renew_seconds,
        'owner'          => 'kube',
        'outdir'         => '/etc/kubernetes/pki',
        # https://v1-23.docs.kubernetes.io/docs/setup/best-practices/certificates/#all-certificates
        'hosts'          => [
            $facts['hostname'],
            $facts['fqdn'],
            $facts['ipaddress'],
            $facts['ipaddress6'],
            $apiserver_clusterip,
            $master_fqdn,
            'kubernetes',
            'kubernetes.default',
            'kubernetes.default.svc',
            'kubernetes.default.svc.cluster',
            'kubernetes.default.svc.cluster.local',
        ],
        'notify_service' => 'kube-apiserver'
    })

    $sa_cert = profile::pki::get_cert($pki_intermediate_base, 'sa', {
        'profile'        => 'service-account-management',
        'renew_seconds'  => $pki_renew_seconds,
        'owner'          => 'kube',
        'outdir'         => '/etc/kubernetes/pki',
        'notify_service' => 'kube-apiserver'
    })
    # FIXME: T329826 ensure we always use the cergen_sa_cert and the PKI sa_cert
    # to validate service-account tokens to not disrupt already provisioned 1.23 clusters.
    $additional_sa_certs = [$cergen_sa_cert['cert'], $sa_cert['cert']]

    # Client certificate used to authenticate against kubelets
    $kubelet_client_cert = profile::pki::get_cert($pki_intermediate_base, 'kube-apiserver-kubelet-client', {
        'renew_seconds'  => $pki_renew_seconds,
        'names'          => [{ 'organisation' => 'system:masters' }],
        'owner'          => 'kube',
        'outdir'         => '/etc/kubernetes/pki',
        'notify_service' => 'kube-apiserver'
    })

    # Client cert for the front proxy (this uses a separate intermediate then everything else)
    # https://v1-23.docs.kubernetes.io/docs/tasks/extend-kubernetes/configure-aggregation-layer/
    $frontproxy_cert = profile::pki::get_cert("${pki_intermediate_base}_front_proxy", 'front-proxy-client', {
        'renew_seconds'  => $pki_renew_seconds,
        'owner'          => 'kube',
        'outdir'         => '/etc/kubernetes/pki',
        'notify_service' => 'kube-apiserver'
    })

    # Fetch a client cert with kubernetes-admin permission
    # This is not actually used by anything but here for convenience of operators
    $default_admin_cert = profile::pki::get_cert($pki_intermediate_base, 'kubernetes-admin', {
        'renew_seconds'  => $pki_renew_seconds,
        'names'           => [{ 'organisation' => 'system:masters' }],
        'owner'           => 'kube',
        'outdir'          => '/etc/kubernetes/pki',
    })
    # Create a supersuer kubeconfig
    k8s::kubeconfig { '/etc/kubernetes/admin.conf':
        master_host => $master_fqdn,
        username    => 'default-admin',
        auth_cert   => $default_admin_cert,
        owner       => 'kube',
        group       => 'kube',
    }

    # Get the local users and the corresponding tokens.
    $_users = $all_infrastructure_users[$kubernetes_cluster_group].filter |$_,$data| {
        # If "constrain_to" is defined, restrict the user to the masters that meet the regexp
        $data['constrain_to'] ? {
            undef => true,
            default => ($facts['fqdn'] =~ Regexp($data['constrain_to']))
        }
    }
    # Ensure all tokens are unique.
    # Kubernetes will use the last definition of a token, so strange things might
    # happen if a token is used twice.
    $_tokens = $_users.map |$_,$data| { $data['token'] }
    if $_tokens != $_tokens.unique {
        fail('Not all tokens in profile::kubernetes::infrastructure_users are unique')
    }

    class { 'k8s::apiserver':
        etcd_servers            => join($etcd_urls, ','),
        apiserver_cert          => $apiserver_cert,
        # FIXME: T329826 the key of the cergen_sa_cert is used to sign service-account tokens in any case
        sa_cert                 => $cergen_sa_cert,
        additional_sa_certs     => $additional_sa_certs,
        kubelet_client_cert     => $kubelet_client_cert,
        frontproxy_cert         => $frontproxy_cert,
        users                   => $_users,
        version                 => $version,
        service_cluster_cidr    => $service_cluster_cidr,
        service_node_port_range => $service_node_port_range,
        admission_plugins       => $admission_plugins,
        admission_configuration => $admission_configuration,
        service_account_issuer  => $master_url,
        ipv6dualstack           => $ipv6dualstack,
    }

    # Setup kube-scheduler
    $scheduler_cert = profile::pki::get_cert($pki_intermediate_base, 'system:kube-scheduler', {
        'renew_seconds'  => $pki_renew_seconds,
        'names'          => [{ 'organisation' => 'system:kube-scheduler' }],
        'owner'          => 'kube',
        'outdir'         => '/etc/kubernetes/pki',
        'notify_service' => 'kube-scheduler',
    })
    $scheduler_kubeconfig = '/etc/kubernetes/scheduler.conf'
    k8s::kubeconfig { $scheduler_kubeconfig:
        master_host => $master_fqdn,
        username    => 'default-scheduler',
        auth_cert   => $scheduler_cert,
        owner       => 'kube',
        group       => 'kube',
    }
    class { 'k8s::scheduler':
        version    => $version,
        kubeconfig => $scheduler_kubeconfig,
    }

    # Setup kube-controller-manager
    $controller_manager_cert = profile::pki::get_cert($pki_intermediate_base, 'system:kube-controller-manager', {
        'renew_seconds'  => $pki_renew_seconds,
        'names'          => [{ 'organisation' => 'system:kube-controller-manager' }],
        'owner'          => 'kube',
        'outdir'         => '/etc/kubernetes/pki',
        'notify_service' => 'kube-controller-manager',
    })
    $controllermanager_kubeconfig = '/etc/kubernetes/controller-manager.conf'
    k8s::kubeconfig { $controllermanager_kubeconfig:
        master_host => $master_fqdn,
        username    => 'default-controller-manager',
        auth_cert   => $controller_manager_cert,
        owner       => 'kube',
        group       => 'kube',
    }
    class { 'k8s::controller':
        # FIXME: T329826 the key of the cergen_sa_cert is used to sign service-account tokens in any case
        service_account_private_key_file => $cergen_sa_cert['key'],
        ca_file                          => $sa_cert['chain'],
        kubeconfig                       => $controllermanager_kubeconfig,
        version                          => $version,
    }

    # All our masters are accessible to all
    ferm::service { 'apiserver-https':
        proto  => 'tcp',
        port   => '6443',
        srange => undef,
    }
}
