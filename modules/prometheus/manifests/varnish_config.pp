# == Define: prometheus::varnish_config
#
# Generate prometheus targets configuration for varnish clusters.
# Data is gathered from conftool using the $selector hash.

# == Parameters
# $dest: The output file where to write the result.
# $selector: Conftool selector to use.
# $port: The port varnish_exporter is listening on.

# == Example
#
#  prometheus::varnish_config{ 'maps_fe':
#      dest     => "${targets_path}/varnish-maps_${::site}_frontend.yaml",
#      selector => { dc      => $::site,
#                    service => 'varnish-fe',
#                    cluster => 'cache_maps' },
#      port     => '9331',
#  }

define prometheus::varnish_config(
  $dest,
  $selector,
  $port,
) {
    validate_string($dest)
    validate_hash($selector)
    validate_re($port, '^[0-9]+$')

    if ! $selector['service'] {
        fail("Selector key 'service' is mandatory")
    }

    file { $dest:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('prometheus/varnish_config.erb'),
    }
}
