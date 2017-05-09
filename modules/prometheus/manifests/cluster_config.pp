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
  $dest,
  $site,
  $cluster,
  $port,
  $labels,
) {
    validate_string($dest)
    validate_string($site)
    validate_string($cluster)
    validate_re($port, '^[0-9]+$')
    validate_hash($labels)

    file { $dest:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('prometheus/cluster_config.erb'),
    }
}
