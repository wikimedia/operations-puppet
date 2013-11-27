class varnish::common::vcl {
    require varnish::common

    file {
        '/etc/varnish/geoip.inc.vcl':
            content => template('varnish/geoip.inc.vcl.erb');
        '/etc/varnish/device-detection.inc.vcl':
            content => template('varnish/device-detection.inc.vcl.erb');
        '/etc/varnish/errorpage.inc.vcl':
            content => template('varnish/errorpage.inc.vcl.erb');
    }
}
