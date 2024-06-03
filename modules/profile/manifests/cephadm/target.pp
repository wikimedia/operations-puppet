# SPDX-License-Identifier: Apache-2.0
# Class: profile::cephadm::target
#
# This profile provides the necessary setup for a node to be
# controlled by cephadm.
class profile::cephadm::target(
    Cephadm::Clusters $cephadm_clusters = lookup('cephadm_clusters'),
    String $cephadm_cluster_label       = lookup('profile::cephadm::cluster_label'),
) {

    $controller = $cephadm_clusters[$cephadm_cluster_label]['controller']
    # Monitor nodes run mgr daemons, and need ssh access to targets
    $mgrs = $cephadm_clusters[$cephadm_cluster_label]['monitors']

    class { 'cephadm::target':
        cephadm_controller => $controller,
        cephadm_mgrs       => $mgrs,
    }
}
