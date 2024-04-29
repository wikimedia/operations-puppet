# SPDX-License-Identifier: Apache-2.0
# == Class: cephadm::monitor
#
# @summary Installs the requirements for a node to be a
# cephadm-managed monitor node, that will run the ceph-mon daemon (and
# maybe also the ceph-mgr daemon). Assumes that this node will also be
# an OSD node, so we just need to additionally open the mon ports.
#
# @param [Array[Stdlib::Host]] cluster_nodes
#     Set of nodes to allow ceph traffice from
class cephadm::monitor(
    Array[Stdlib::Host] $cluster_nodes,
) {

    firewall::service { 'ceph-mon':
        proto   => 'tcp',
        port    => [3300, 6789],
        notrack => true,
        srange  => $cluster_nodes,
    }
}
