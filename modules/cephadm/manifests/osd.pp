# SPDX-License-Identifier: Apache-2.0
# == Class: cephadm::osd
#
# @summary Installs the requirements for a node to be a
# cephadm-managed OSD node (i.e. a storage server). This is mostly
# firewall rules and custom facts for determining what storage is
# available for Ceph use.
#
# @param [Array[Stdlib::Host]] cluster_nodes
#     Set of nodes to allow ceph traffice from
class cephadm::osd(
    Array[Stdlib::Host] $cluster_nodes,
) {

    firewall::service { 'ceph-daemons':
        proto      => 'tcp',
        port_range => [6800, 7300],
        notrack    => true,
        srange     => $cluster_nodes,
    }

    # TODO: custom fact for storage layout
}
