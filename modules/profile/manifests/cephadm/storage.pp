# SPDX-License-Identifier: Apache-2.0
# Class: profile::cephadm::storage
#
# This profile provides the necessary setup for a cephadm-controlled
# storage node.
class profile::cephadm::storage(
    Cephadm::Clusters $cephadm_clusters = lookup('cephadm_clusters'),
    String $cephadm_cluster_label       = lookup('profile::cephadm::cluster_label'),
) {
    require profile::cephadm::target

    # Use the performance governor for our storage nodes
    class { 'cpufrequtils':
        governor => 'performance',
    }

    $osds = $cephadm_clusters[$cephadm_cluster_label]['osds']
    $monitors = $cephadm_clusters[$cephadm_cluster_label]['monitors']
    if 'rgws' in $cephadm_clusters[$cephadm_cluster_label] {
        $rgws = $cephadm_clusters[$cephadm_cluster_label]['rgws']
    } else {
        $rgws = []
    }
    $cluster_nodes = unique($monitors + $osds + $rgws)

    class { 'cephadm::osd':
        cluster_nodes => $cluster_nodes,
    }

    if member($monitors, $::fqdn) {
        class { 'cephadm::monitor':
            cluster_nodes => $cluster_nodes,
        }
    }
}
