class varnish::common::vcl {
    require "varnish::common"

    file {
        "/etc/varnish/geoip.inc.vcl":
            content => template("${module_name}/vcl/geoip.inc.vcl.erb");
        "/etc/varnish/device-detection.inc.vcl":
            content => template("${module_name}/vcl/device-detection.inc.vcl.erb");
        "/etc/varnish/errorpage.inc.vcl":
            content => template("${module_name}/vcl/errorpage.inc.vcl.erb");
    }
}
