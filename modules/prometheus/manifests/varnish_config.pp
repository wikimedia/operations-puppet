# == Define: prometheus::varnish_config
#
# Generate prometheus targets configuration for varnish clusters.
# Data is gathered using get_clusters()

# == Parameters
# $dest:    The output file where to write the result.
# $site:    The site to use.
# $cluster: The cluster to use.
# $port:    The port varnish_exporter is listening on.
# $labels:  Labels to attach to the cluster's hosts.

# == Example
#
#  prometheus::varnish_config{ 'maps_fe':
#      dest    => "${targets_path}/varnish-maps_${::site}_frontend.yaml",
#      site    => $::site,
#      cluster => 'cache_maps',
#      port    => '9331',
#      labels  => {'layer' => 'frontend' },
#  }

define prometheus::varnish_config(
  $dest,
  $site,
  $cluster,
  $port,
  $labels,
) {
    validate_string($dest)
    validate_string($site)
    validate_hash($cluster)
    validate_re($port, '^[0-9]+$')
    validate_hash($labels)

    $hosts = get_clusters({
      'site' => $site,
      'cluster' => $cluster,
    })

    file { $dest:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('prometheus/varnish_config.erb'),
    }
}
