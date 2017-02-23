class k8s::kubelet(
    $master_host,
    $listen_address = '0.0.0.0',
    $listen_port = undef,
    $cluster_dns_ip = '192.168.0.100',
    $use_package = false,
    $pod_infra_container_image = 'gcr.io/google_containers/pause:2.0',
    $cluster_domain = 'kube',
    $tls_cert = '/var/lib/kubernetes/ssl/certs/cert.pem',
    $tls_key = '/var/lib/kubernetes/ssl/private_keys/server.key',
    $cni=false,
    $cni_bin_dir='/opt/cni/bin',
    $cni_conf_dir='/etc/cni/net.d',
) {
    include ::k8s::infrastructure_config

    # Use this to maintain compatibility with labs for now
    if $use_package {
        require_package('kubernetes-node')
    } else {
        file { '/usr/bin/kubelet':
            ensure => link,
            target => '/usr/local/bin/kubelet',
        }
    }

    # Needed on k8s nodes for kubectl proxying to work
    ensure_packages(['socat'])

    file { '/etc/default/kubelet':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('k8s/kubelet.default.erb'),
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

    base::service_unit { 'kubelet':
        systemd   => true,
        subscribe => File['/etc/kubernetes/kubeconfig'],
    }
}
