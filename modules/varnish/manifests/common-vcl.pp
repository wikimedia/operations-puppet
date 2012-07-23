class varnish::common-vcl {
  require varnish::common

  file { '/etc/varnish/geoip.inc.vcl':
    content => template('varnish/geoip.inc.vcl.erb');
  }
}
