# SPDX-License-Identifier: Apache-2.0
# Satisfy the WMF style guide
class profile::alerts::deploy::prometheus {
    $enabled_k8s_clusters = k8s::fetch_clusters(false).filter | String $_, K8s::ClusterConfig $config | {
        $config['dc'] == $::site and 'prometheus' in $config
    }
    $k8s_prometheus_names = $enabled_k8s_clusters.map |String $_, K8s::ClusterConfig $c| {
        $c['prometheus']['name']
    }

    class { 'alerts::deploy::prometheus':
        instances => ['analytics', 'ext', 'ops', 'services', 'cloud'] + $k8s_prometheus_names
    }
}
