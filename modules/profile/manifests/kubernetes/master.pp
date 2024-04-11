# SPDX-License-Identifier: Apache-2.0
# @summary
#   This class sets up a kubernetes master (apiserver)
#
class profile::kubernetes::master (
    String $kubernetes_cluster_name = lookup('profile::kubernetes::cluster_name'),
    Array  $prometheus_all_nodes    = lookup('prometheus_all_nodes'),
) {
    $k8s_config = k8s::fetch_cluster_config($kubernetes_cluster_name)
    # Comma separated list of etcd URLs is consumed by the kube-publish-sa-cert service
    # as well as k8s::apiserser so we produce it here.
    $etcd_servers = join($k8s_config['etcd_urls'], ',')

    # FIXME: Ensure kube user/group as well as /etc/kubernetes/pki is created with proper permissions
    # before the first pki::get_cert call: https://phabricator.wikimedia.org/T337826
    unless defined(Group['kube']) {
        group { 'kube':
            ensure => present,
            system => true,
        }
    }
    unless defined(User['kube']) {
        user { 'kube':
            ensure => present,
            gid    => 'kube',
            system => true,
            home   => '/nonexistent',
            shell  => '/usr/sbin/nologin',
        }
    }
    $cert_dir = '/etc/kubernetes/pki'
    unless defined(File[$cert_dir]) {
        file { $cert_dir:
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    # Install kubectl matching the masters kubernetes version
    # (that's why we don't use profile::kubernetes::client)
    class { 'k8s::client':
        version => $k8s_config['version'],
    }

    # The first useable IPv4 IP of the service cluster-cidr is automatically used as ClusterIP for the internal
    # kubernetes apiserver service (kubernetes.default.cluster.local)
    $apiserver_clusterip = wmflib::cidr_first_address($k8s_config['service_cluster_cidr']['v4'])
    $apiserver_cert = profile::pki::get_cert($k8s_config['pki_intermediate_base'], 'kube-apiserver', {
        'profile'         => 'server',
        'renew_seconds'   => $k8s_config['pki_renew_seconds'],
        'owner'           => 'kube',
        'outdir'          => $cert_dir,
        # https://v1-23.docs.kubernetes.io/docs/setup/best-practices/certificates/#all-certificates
        'hosts'           => [
            $facts['networking']['hostname'],
            $facts['networking']['fqdn'],
            $facts['networking']['ip'],
            $facts['networking']['ip6'],
            $apiserver_clusterip,
            $k8s_config['master'],
            'kubernetes',
            'kubernetes.default',
            'kubernetes.default.svc',
            'kubernetes.default.svc.cluster',
            'kubernetes.default.svc.cluster.local',
        ],
        'notify_services' => ['kube-apiserver-safe-restart', 'kube-controller-manager', 'kube-scheduler'],
    })

    $sa_cert = profile::pki::get_cert($k8s_config['pki_intermediate_base'], 'sa', {
        'profile'         => 'service-account-management',
        'renew_seconds'   => $k8s_config['pki_renew_seconds'],
        'owner'           => 'kube',
        'outdir'          => $cert_dir,
        'notify_services' => ['kube-apiserver-safe-restart', 'kube-publish-sa-cert'],
    })

    $confd_prefix = '/kube-apiserver-sa-certs'
    # Add a one-shot service that writes the public sa_cert to etcd for all control-planes to fetch
    systemd::service { 'kube-publish-sa-cert':
        content => systemd_template('kubernetes-publish-sa-cert'),
    }
    # Setup a confd instance with the k8s etcd as backend (to fetch other control-planes sa certs from)
    $instances = {
        'k8s' => {
            'ensure'  => 'present',
            'backend' => 'etcdv3',
            'prefix'  => $confd_prefix,
            # confd with etcdv3 does not work well with srv_dns as it does not prepend the scheme in that case
            'hosts'   => $k8s_config['etcd_urls'],
        },
    }
    class { 'profile::confd':
        instances => $instances,
    }
    # Write out the service account certs form all control-planes into one file
    $other_apiserver_sa_certs = '/etc/kubernetes/pki/kube-apiserver-sa-certs.pem'
    confd::file { $other_apiserver_sa_certs:
        ensure     => present,
        instance   => 'k8s',
        watch_keys => ['/'],
        # Add all but the local cert to the file (the local one will be used unconditionally)
        content    => "{{range gets \"/*\"}}{{if ne .Key \"/${facts['networking']['fqdn']}\"}}{{.Value}}{{end}}{{end}}",
        reload     => '/bin/systemctl restart kube-apiserver-safe-restart.service',
    }

    # Client certificate used to authenticate against kubelets
    $kubelet_client_cert = profile::pki::get_cert($k8s_config['pki_intermediate_base'], 'kube-apiserver-kubelet-client', {
        'renew_seconds'   => $k8s_config['pki_renew_seconds'],
        'names'           => [{ 'organisation' => 'system:masters' }],
        'owner'           => 'kube',
        'outdir'          => $cert_dir,
        'notify_services' => ['kube-apiserver-safe-restart'],
    })

    # Client cert for the front proxy (this uses a separate intermediate then everything else)
    # https://v1-23.docs.kubernetes.io/docs/tasks/extend-kubernetes/configure-aggregation-layer/
    $frontproxy_cert = profile::pki::get_cert("${k8s_config['pki_intermediate_base']}_front_proxy", 'front-proxy-client', {
        'renew_seconds'   => $k8s_config['pki_renew_seconds'],
        'owner'           => 'kube',
        'outdir'          => $cert_dir,
        'notify_services' => ['kube-apiserver-safe-restart'],
    })

    # Fetch a client cert with kubernetes-admin permission
    # This is not actually used by anything but here for convenience of operators
    $default_admin_cert = profile::pki::get_cert($k8s_config['pki_intermediate_base'], 'kubernetes-admin', {
        'renew_seconds'   => $k8s_config['pki_renew_seconds'],
        'names'           => [{ 'organisation' => 'system:masters' }],
        'owner'           => 'kube',
        'outdir'          => $cert_dir,
    })
    # Create a superuser kubeconfig connecting locally to this control-plane
    file { '/root/.kube':
        ensure => directory,
        mode   => '0750',
    }
    k8s::kubeconfig { '/root/.kube/config':
        master_host => $facts['networking']['fqdn'],
        username    => 'default-admin',
        auth_cert   => $default_admin_cert,
        owner       => 'root',
        group       => 'root',
    }

    class { 'k8s::apiserver':
        etcd_servers            => $etcd_servers,
        apiserver_cert          => $apiserver_cert,
        sa_cert                 => $sa_cert,
        additional_sa_certs     => [$other_apiserver_sa_certs,],
        kubelet_client_cert     => $kubelet_client_cert,
        frontproxy_cert         => $frontproxy_cert,
        version                 => $k8s_config['version'],
        service_cluster_cidr    => $k8s_config['service_cluster_cidr'],
        service_node_port_range => $k8s_config['service_node_port_range'],
        admission_plugins       => $k8s_config['admission_plugins'],
        admission_configuration => $k8s_config['admission_configuration'],
        service_account_issuer  => $k8s_config['master_url'],
        ipv6dualstack           => $k8s_config['ipv6dualstack'],
        audit_policy            => $k8s_config['audit_policy'],
    }

    # Don't page for staging clusters
    $severity = 'staging' in $kubernetes_cluster_name ? {
        true    => 'critical',
        default => 'page',
    }
    # The default reneval time is ~11 days before expiry (1 day for staging)
    # So all(?) other certificate checks in the infrastructure start alerting when
    # a certificate expires in <=10 days. Try to allign with that here but keeping
    # the flexibility to have shorter expiry times (for staging) by using
    # pki_renew_seconds (in days) minus 1 day with a minimum of 1 day before expiry.
    $certificate_expiry_days = max(ceiling($k8s_config['pki_renew_seconds'] / 60 / 60 / 24) - 1, 1)
    # Add a blackbox check for the kube-apiserver
    prometheus::blackbox::check::http { "${kubernetes_cluster_name}-kube-apiserver":
        server_name             => $k8s_config['master'],
        team                    => 'sre',
        severity                => $severity,
        path                    => '/readyz',
        port                    => 6443,
        force_tls               => true,
        certificate_expiry_days => $certificate_expiry_days,
        prometheus_instance     => 'ops',
    }

    # Setup kube-scheduler
    $scheduler_cert = profile::pki::get_cert($k8s_config['pki_intermediate_base'], 'system:kube-scheduler', {
        'renew_seconds'   => $k8s_config['pki_renew_seconds'],
        'names'           => [{ 'organisation' => 'system:kube-scheduler' }],
        'owner'           => 'kube',
        'outdir'          => $cert_dir,
        'notify_services' => ['kube-scheduler'],
    })
    $scheduler_kubeconfig = '/etc/kubernetes/scheduler.conf'
    k8s::kubeconfig { $scheduler_kubeconfig:
        master_host => $facts['networking']['fqdn'],
        username    => 'default-scheduler',
        auth_cert   => $scheduler_cert,
        owner       => 'kube',
        group       => 'kube',
    }
    class { 'k8s::scheduler':
        version              => $k8s_config['version'],
        kubeconfig           => $scheduler_kubeconfig,
        # Use the apiserver cert for HTTPS (it has the correct SAN)
        tls_cert_file        => $apiserver_cert['chained'],
        tls_private_key_file => $apiserver_cert['key'],
    }

    # Setup kube-controller-manager
    $controller_manager_cert = profile::pki::get_cert($k8s_config['pki_intermediate_base'], 'system:kube-controller-manager', {
        'renew_seconds'   => $k8s_config['pki_renew_seconds'],
        'names'           => [{ 'organisation' => 'system:kube-controller-manager' }],
        'owner'           => 'kube',
        'outdir'          => $cert_dir,
        'notify_services' => ['kube-controller-manager'],
    })
    $controllermanager_kubeconfig = '/etc/kubernetes/controller-manager.conf'
    k8s::kubeconfig { $controllermanager_kubeconfig:
        master_host => $facts['networking']['fqdn'],
        username    => 'default-controller-manager',
        auth_cert   => $controller_manager_cert,
        owner       => 'kube',
        group       => 'kube',
    }
    class { 'k8s::controller':
        service_account_private_key_file => $sa_cert['key'],
        ca_file                          => $sa_cert['chain'],
        kubeconfig                       => $controllermanager_kubeconfig,
        version                          => $k8s_config['version'],
        # Use the apiserver cert for HTTPS (it has the correct SAN)
        tls_cert_file                    => $apiserver_cert['chained'],
        tls_private_key_file             => $apiserver_cert['key'],
    }

    # Configure rsyslog to forward audit logs to kafka
    $ensure_audit_log = $k8s_config['audit_policy'] ? {
        undef   => absent,
        ''      => absent,
        default => present,
    }
    rsyslog::input::file { 'kubernetes-audit':
        ensure             => $ensure_audit_log,
        path               => '/var/log/kubernetes/audit.log',
        reopen_on_truncate => 'on',
        addmetadata        => 'on',
        addceetag          => 'on',
        syslog_tag         => 'kubernetes',
        priority           => 8,
    }

    # All our masters are accessible to all
    ferm::service { 'apiserver-https':
        proto  => 'tcp',
        port   => '6443',
        srange => undef,
    }

    # Allow prometheus to scrape:
    # * kube-controller-manager (10257)
    # * kube-scheduler (10259)
    $prometheus_nodes_ferm = join($prometheus_all_nodes, ' ')
    ferm::service { 'prometheus-metrics':
        proto  => 'tcp',
        port   => [10257, 10259],
        srange => "(@resolve((${prometheus_nodes_ferm})))",
    }
}
