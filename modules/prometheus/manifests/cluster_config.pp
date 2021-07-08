# == Define: prometheus::cluster_config
#
# Generate prometheus targets configuration for WMF clusters.
# Data is gathered using get_clusters()

# == Parameters
# $dest:    The output file where to write the result.
# $site:    The site to use.
# $cluster: The cluster to use.
# $port:    The port to use for the target.
# $labels:  Labels to attach to the cluster's hosts.
# $ensure:  Ensure the target is present/absent

# == Example
#
#  Configuration for varnish_exporter for upload, running on the frontend varnish
#  instance.
#
#  prometheus::cluster_config{ 'maps_fe':
#      dest    => "${targets_path}/varnish-maps_${::site}_frontend.yaml",
#      site    => $::site,
#      cluster => 'cache_upload',
#      port    => '9331',
#      labels  => {'layer' => 'frontend' },
#  }

define prometheus::cluster_config(
  String $dest,
  String $site,
  String $cluster,
  Stdlib::Port $port,
  Hash $labels,
) {
    $data = get_clusters({'site' => [$site], 'cluster' => [$cluster]}).map |$cluster_items| {
        # $cluster_items is a tuple of ($cluster, $sites)
        $cluster_items[1].map |$site_items| {
            # $site_items is a tuple of ($site, $targets)
            $targets = $site_items[1].map |$target| { "${target.split('\.')[0]}:${port}" }
            $item = {
                'targets' => $targets,
                'labels' => $labels,
            }
            $item
        }
    }.flatten

    file { $dest:
        ensure  => stdlib::ensure(!$data.empty, 'file'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "# This file is managed by puppet\n${data.ordered_yaml}\n"
    }
}
