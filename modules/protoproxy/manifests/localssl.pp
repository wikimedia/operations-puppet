# vim:sw=4:ts=4:et:

# == Definition: protoproxy::localssl
#
# This definition creates a SSL proxy to localhost, using nginx site.
# The parameters are merely expanded in the templates which has all
# of the logic.
#
# === Parameters:
# [*proxy_server_name*]
#
# [*proxy_server_cert_name*]
#
# [*enabled*]
# Whether to enable the site configuration. It will always be generated under
# /etc/nginx/sites-available , enabling this parameter will create a symbolic
# link under /etc/nginx/sites-enabled.
# Defaults to true
#
# [*upstream_port*]
# The TCP port to proxy to.
# Defaults to '80'

define protoproxy::localssl(
    $proxy_server_name,
    $proxy_server_cert_name,
    $enabled=true
    $upstream_port='80'
) {
    require protoproxy::package
    include protoproxy::service

    # The WMF nginx module is pretty bad, and it's almost pointless to use it here.

    file { "/etc/nginx/sites-available/${name}":
        content => template("${module_name}/localssl.erb");
    }

    nginx_site { $name:
        require => File["/etc/nginx/sites-available/${name}"],
        enable  => $enabled,
        notify  => Service[nginx]
    }
}
