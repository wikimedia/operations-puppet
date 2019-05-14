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
    file { $dest:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('prometheus/cluster_config.erb'),
    }
}
