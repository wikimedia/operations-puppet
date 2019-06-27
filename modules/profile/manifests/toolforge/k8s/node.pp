class profile::toolforge::k8s::node(
    Array[Stdlib::Fqdn] $k8s_master_hosts = lookup('profile::toolforge::k8s_masters_hosts', {default_value => ['localhost']}),
    Stdlib::Fqdn        $k8s_master_fqdn  = lookup('profile::toolforge::k8s_master_fqdn',   {default_value => 'k8smaster.eqiad.wmflabs'}),
    Boolean             $swap_partition   = lookup('swap_partition',                        {default_value => true}),
) {
    # This profile is for Debian Stretch specifically. No support for Buster yet.
    requires_os('debian == stretch')

    # TODO: flannel/calico/CNI-whatever is explicitly excluded in this first
    # iteration of the puppet code, as well as some other ferm configs
    # TODO: no proxy setup yet.
    # TODO: track Buster support for k8s in prod deployments

    # disable swap: kubelet doesn't want it
    if $swap_partition {
        fail('Please set the swap_partition hiera key to false for this VM')
    }
    exec { 'toolforge_k8s_disable_swap':
        command => '/sbin/swapoff -a',
        onlyif  => '/usr/bin/test $(swapon -s | wc -l) -gt 0',
    }

    # the certificate trick
    $k8s_cert_pub     = '/etc/kubernetes/ssl/cert.pem'
    $k8s_cert_priv    = '/etc/kubernetes/ssl/cert.priv'
    $k8s_cert_ca      = '/etc/kubernetes/ssl/ca.pem'
    $puppet_cert_pub  = "/var/lib/puppet/ssl/certs/${::fqdn}.pem"
    $puppet_cert_priv = "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem"
    $puppet_cert_ca   = '/var/lib/puppet/ssl/certs/ca.pem'

    file { '/etc/kubernetes/ssl/':
        ensure => directory,
    }

    file { $k8s_cert_pub:
        ensure => present,
        source => "file://${puppet_cert_pub}",
        owner  => 'kube',
        group  => 'kube',
    }

    file { $k8s_cert_priv:
        ensure    => present,
        source    => "file://${puppet_cert_priv}",
        owner     => 'kube',
        group     => 'kube',
        mode      => '0640',
        show_diff => false,
    }

    file { $k8s_cert_ca:
        ensure => present,
        source => "file://${puppet_cert_ca}",
        owner  => 'kube',
        group  => 'kube',
    }

    $docker_version = '1.12.6-0~debian-jessie'

    class { '::profile::docker::storage':
        physical_volumes => '/dev/vda4',
        vg_to_remove     => 'vd',
    }

    class { '::profile::docker::engine':
        settings        => {
            'iptables'     => false,
            'ip-masq'      => false,
            'live-restore' => true,
        },
        version         => $docker_version,
        declare_service => true,
        require         => Class['::profile::docker::storage'],
    }

    file { '/etc/kubernetes':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/kubernetes/kubeconfig':
        ensure  => present,
        content => template('profile/toolforge/k8s/kubeconfig-node.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes'],
    }

    class { '::k8s::kubelet':
        listen_address            => '0.0.0.0',
        cni                       => false,
        pod_infra_container_image => 'docker-registry.tools.wmflabs.org/pause:2.0',
        tls_cert                  => $k8s_cert_pub,
        tls_key                   => $k8s_cert_priv,
        kubeconfig                => '/etc/kubernetes/kubeconfig',
#        node_labels               => $kubelet_node_labels,
#        node_taints               => $kubelet_node_taints,
#        extra_params              => $kubelet_extra_params,
    }

    # Firewall!  Kubelet opens some scary ports to the outside world,
    #  so this class just closes those particular ports whilst leaving everything
    #  else in the hands of the OpenStack security groups.
    $master_hosts_ferm = join($k8s_master_hosts, ' ')
    ferm::service { 'kubelet-http':
        proto  => 'tcp',
        port   => '10250',
        srange => "@resolve((${master_hosts_ferm}))",
    }
    ferm::service { 'kubelet-http-readonly-prometheus':
        proto  => 'tcp',
        port   => '10255',
        srange => "@resolve((${master_hosts_ferm}))",
    }
}
