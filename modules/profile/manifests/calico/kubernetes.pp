# == Class profile::calico::kubernetes
#
# Installs calico for use in a kubernetes cluster.
# This follows https://docs.projectcalico.org/getting-started/kubernetes/#manual-installation
# It also optionally deploys Istio CNI configurations, since (Istio) upstream
# suggests to use a chained config with Calico.

class profile::calico::kubernetes (
    Calico::CalicoVersion $calico_version = lookup('profile::calico::kubernetes::calico_version', { default_value => '3.17' }),
    String $calico_cni_username = lookup('profile::calico::kubernetes::calico_cni::username', { default_value => 'calico-cni' }),
    String $calico_cni_token = lookup('profile::calico::kubernetes::calico_cni::token'),
    String $calicoctl_username = lookup('profile::calico::kubernetes::calicoctl::username', { default_value => 'calicoctl' }),
    String $calicoctl_token = lookup('profile::calico::kubernetes::calicoctl::token'),
    Stdlib::Host $master_fqdn = lookup('profile::kubernetes::master_fqdn'),
    Array[Stdlib::Host] $bgp_peers = lookup('profile::calico::kubernetes::bgp_peers'),
    Hash $calico_cni_config = lookup('profile::calico::kubernetes::cni_config'),
    String $istio_cni_username = lookup('profile::calico::kubernetes::istio_cni_username', { default_value => 'istio-cni' }),
    Optional[String] $istio_cni_token = lookup('profile::calico::kubernetes::istio_cni_token', { default_value => undef }),
    String $istio_cni_version = lookup('profile::calico::kubernetes::istio_cni_version', { default_value => '1.9.5' }),
    Wmflib::Ensure $ensure_istio_cni = lookup('profile::calico::kubernetes::ensure_istio_cni', { default_value => 'present' }),
) {
    class { 'calico':
        master_fqdn        => $master_fqdn,
        calicoctl_username => $calicoctl_username,
        calicoctl_token    => $calicoctl_token,
        calico_version     => $calico_version,
    }

    k8s::kubelet::cni { 'calico':
        priority => 10,
        config   => $calico_cni_config,
    }

    k8s::kubeconfig { '/etc/cni/net.d/calico-kubeconfig':
        master_host => $master_fqdn,
        username    => $calico_cni_username,
        token       => $calico_cni_token,
        require     => File['/etc/cni/net.d'],
    }

    if $istio_cni_token {
        $istio_cni_version_safe = regsubst($istio_cni_version, '\.', '', 'G')
        apt::package_from_component { "istio${istio_cni_version_safe}":
            component => "component/istio${istio_cni_version_safe}",
            packages  => { 'istio-cni' => $ensure_istio_cni },
        }
        k8s::kubeconfig { '/etc/cni/net.d/istio-kubeconfig':
            ensure      => $ensure_istio_cni,
            master_host => $master_fqdn,
            username    => $istio_cni_username,
            token       => $istio_cni_token,
            require     => File['/etc/cni/net.d'],
        }
    }

    # TODO: We need to configure BGP peers in calico datastore (helm chart) as well.
    $bgp_peers_ferm = join($bgp_peers, ' ')
    ferm::service { 'calico-bird':
        proto  => 'tcp',
        port   => '179', # BGP
        srange => "(@resolve((${bgp_peers_ferm})) @resolve((${bgp_peers_ferm}), AAAA))",
    }
    # All nodes need to talk to typha and it runs as hostNetwork pod
    # TODO: If and when we move to a layered BGP hierarchy, revisit the use of
    # $bgp_peers.
    ferm::service { 'calico-typha':
        proto  => 'tcp',
        port   => '5473',
        srange => "(@resolve((${bgp_peers_ferm})) @resolve((${bgp_peers_ferm}), AAAA))",
    }
}
