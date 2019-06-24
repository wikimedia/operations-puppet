# == Class profile::calico::kubernetes
#
# Installs calico for use in a kubernetes cluster.
# This follows http://docs.projectcalico.org/v2.0/getting-started/kubernetes/installation/#manual-installation

class profile::calico::kubernetes(
    $etcd_endpoints = hiera('profile::calico::kubernetes::etcd_endpoints'),
    $bgp_peers = hiera('profile::calico::kubernetes::bgp_peers'),
    $calico_version = hiera('profile::calico::kubernetes::calico_version'),
    $registry = hiera('profile::calico::kubernetes::docker::registry'),
    $kubeconfig = hiera('profile::kubernetes::node::kubelet_config'),
) {

    class { '::calico':
        etcd_endpoints => $etcd_endpoints,
        calico_version => $calico_version,
        registry       => $registry,
    }

    class { '::calico::cni':
        kubeconfig => $kubeconfig,
    }

    $bgp_peers_ferm = join($bgp_peers, ' ')
    ferm::service { 'calico-bird':
        proto  => 'tcp',
        port   => '179', # BGP
        srange => "(@resolve((${bgp_peers_ferm})) @resolve((${bgp_peers_ferm}), AAAA))",
    }
}
