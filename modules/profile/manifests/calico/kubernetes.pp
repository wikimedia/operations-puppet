# == Class profile::calico::kubernetes
#
# Installs calico for use in a kubernetes cluster.
# This follows http://docs.projectcalico.org/v2.0/getting-started/kubernetes/installation/#manual-installation

class profile::calico::kubernetes(
    Array[String] $etcd_endpoints = lookup('profile::calico::kubernetes::etcd_endpoints'),
    $bgp_peers = lookup('profile::calico::kubernetes::bgp_peers'),
    String $calico_version = lookup('profile::calico::kubernetes::calico_version'),
    Stdlib::Host $registry = lookup('profile::calico::kubernetes::docker::registry'),
    Stdlib::Unixpath $kubeconfig = lookup('profile::kubernetes::node::kubelet_config'),
    String $datastore_type = lookup('profile::calico::kubernetes::calico_datastore_type', {default_value => 'etcdv2'}),
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes', {default_value => []}),
){

    class { '::calico':
        etcd_endpoints => $etcd_endpoints,
        calico_version => $calico_version,
        datastore_type => $datastore_type,
        registry       => $registry,
    }

    class { '::calico::cni':
        kubeconfig     => $kubeconfig,
        datastore_type => $datastore_type,
    }

    $bgp_peers_ferm = join($bgp_peers, ' ')
    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')

    ferm::service { 'calico-bird':
        proto  => 'tcp',
        port   => '179', # BGP
        srange => "(@resolve((${bgp_peers_ferm})) @resolve((${bgp_peers_ferm}), AAAA))",
    }
    ferm::service { 'calico-felix-prometheus':
        proto  => 'tcp',
        port   => '9091', # prometheus
        srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }
}
