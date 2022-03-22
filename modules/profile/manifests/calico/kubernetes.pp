# == Class profile::calico::kubernetes
#
# Installs calico for use in a kubernetes cluster.
# This follows https://docs.projectcalico.org/getting-started/kubernetes/#manual-installation

class profile::calico::kubernetes(
    String $calico_version = lookup('profile::calico::kubernetes::calico_version'),
    String $calico_cni_username = lookup('profile::calico::kubernetes::calico_cni::username', {default_value => 'calico-cni'}),
    String $calico_cni_token = lookup('profile::calico::kubernetes::calico_cni::token'),
    String $calicoctl_username = lookup('profile::calico::kubernetes::calicoctl::username', {default_value => 'calicoctl'}),
    String $calicoctl_token = lookup('profile::calico::kubernetes::calicoctl::token'),
    Stdlib::Host $master_fqdn = lookup('profile::kubernetes::master_fqdn'),
    Array[Stdlib::Host] $bgp_peers = lookup('profile::calico::kubernetes::bgp_peers'),
    Hash $calico_cni_config = lookup('profile::calico::kubernetes::cni_config'),
){

    class { '::calico':
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
