#

@monitor_group { 'cache_bits_pmtpa': description => 'pmtpa bits Varnish' }
@monitor_group { 'cache_bits_eqiad': description => 'eqiad bits Varnish '}
@monitor_group { 'cache_bits_esams': description => 'esams bits Varnish' }
@monitor_group { 'cache_mobile_eqiad': description => 'eqiad mobile Varnish' }

class varnish {
  # Make a default instance
  varnish::instance { 'default': }
}
