#  Class that sets up and configures kubelet
class k8s::kubelet(
    String $kubeconfig,
    String $pod_infra_container_image,
    String $listen_address,
    Boolean $cni,
    Optional[Stdlib::Port] $listen_port = undef,
    String $cluster_domain = 'kube',
    Optional[String] $cluster_dns = undef,
    String $tls_cert = '/var/lib/kubernetes/ssl/certs/cert.pem',
    String $tls_key = '/var/lib/kubernetes/ssl/private_keys/server.key',
    String $cni_bin_dir = '/opt/cni/bin',
    String $cni_conf_dir = '/etc/cni/net.d',
    Boolean $fqdn_as_hostname = true,
    Boolean $logtostderr = true,
    Integer $v_log_level = 0,
    Boolean $packages_from_future=false,
    Boolean $kubelet_ipv6=false,
    Optional[Array[String]] $node_labels = [],
    Optional[Array[String]] $node_taints = [],
    Optional[Array[String]] $extra_params = undef,
) {
    if $packages_from_future {
        apt::package_from_component { 'kubelet-kubernetes-future':
            component => 'component/kubernetes-future',
            packages  => ['kubernetes-node'],
        }
        # apparmor is needed for PodSecurityPolicy to be able to enforce profiles
        ensure_packages('apparmor')
    } else {
        require_package('kubernetes-node')
        # Old kubernetes nodes can't create containers when apparmor is installed (due to missing profiles)
        # Bug: T273563
        # TODO: Remove this after all clusters have been upgraded to kubernetes >=1.16
        package {'apparmor': ensure => purged}
    }

    # socat is needed on k8s nodes for kubectl proxying to work
    ensure_packages('socat')

    file { '/etc/default/kubelet':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('k8s/kubelet.default.erb'),
        notify  => Service['kubelet'],
    }

    file { [
        '/var/run/kubernetes',
        '/var/lib/kubelet',
    ] :
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0700',
    }

    service { 'kubelet':
        ensure    => running,
        enable    => true,
        subscribe => [
            File[$kubeconfig],
            File['/etc/default/kubelet'],
        ],
    }

}
