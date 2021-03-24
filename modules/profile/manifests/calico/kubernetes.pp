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
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes', {default_value => []}),
){

    class { '::calico':
        master_fqdn        => $master_fqdn,
        calicoctl_username => $calicoctl_username,
        calicoctl_token    => $calicoctl_token,
        calico_version     => $calico_version,
    }

    class { '::calico::cni':
        master_fqdn         => $master_fqdn,
        calico_cni_username => $calico_cni_username,
        calico_cni_token    => $calico_cni_token,
    }

    # TODO: We need to configure BGP peers in calico datastore (helm chart) as well.
    $bgp_peers_ferm = join($bgp_peers, ' ')
    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')

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
    ferm::service { 'calico-felix-prometheus':
        proto  => 'tcp',
        port   => '9091', # Prometheus metrics port of calico node pods (running in host network namespace)
        srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }
    ferm::service { 'calico-typha-prometheus':
        proto  => 'tcp',
        port   => '9093', # Prometheus metrics port of calico typha pods (running in host network namespace)
        srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }
}
