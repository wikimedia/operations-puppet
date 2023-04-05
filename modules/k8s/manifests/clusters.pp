# SPDX-License-Identifier: Apache-2.0
# @summary class to allow us to load yaml data reducing the need to do so for every function call
class k8s::clusters {
    $defaults            = lookup('kubernetes::clusters_defaults', { 'default_value' => {} })  # lint:ignore:wmf_styleguide
    $kubernetes_clusters = lookup('kubernetes::clusters', { 'default_value' => {} })  # lint:ignore:wmf_styleguide

    # Inject default config if clusters don't specify it explicitely
    # Also inject the cluster group name into every cluster hash for easy lookup
    $by_group = $kubernetes_clusters.reduce({}) | $gmemo, $gkey | {
      $group = $gkey[0]
      $clusters = $gkey[1]
      $new_clusters = $clusters.reduce({}) | $cmemo, $ckey | {
        $name = $ckey[0]
        $config = $ckey[1]
        # Add the clusters group to the config hash of each cluster
        $merged = deep_merge($defaults, { 'cluster_group' => $group }, $config)
        $final_merge = deep_merge({
          # Add additional generated config options to each clusters config
          'master_url' => "https://${merged['master']}:${merged['master_port']}",
        }, $merged)

        # Add this cluster again under it's name and alias, in case that is defined
        if 'cluster_alias' in $final_merge {
          $cmemo + { $final_merge['cluster_alias'] => $final_merge } + { $name => $final_merge }
        } else {
          $cmemo + { $name => $final_merge }
        }
      }
      $gmemo + { $group => $new_clusters }
    }

    $by_cluster = $by_group.reduce({}) | $memo, $key | { $memo + $key[1] }
    # TODO: Should the structure be validated here? It will be validated in k8s::fetch_cluster_config()
}
