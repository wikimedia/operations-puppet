# == Define: protoproxy::localssl
#
# This definition creates a SSL proxy to localhost, using an Nginx site.
#
# === Parameters:
# [*proxy_server_cert_name*]
#
# [*upstream_port*]
#   TCP port to proxy to. Defaults to '80'
#

define protoproxy::localssl(
    $proxy_server_cert_name,
    $enabled       = true,
    $upstream_port = '80'
) {
    nginx::site { 'localssl':
        content => template('protoproxy/localssl.erb'),
        enabled => $enabled,
    }
}
