# == Define: protoproxy::localssl
#
# This definition creates a SSL proxy to localhost, using an Nginx site.
#
# === Parameters:
# [*server_name*]
#   Server name, used e.g. for SNI. Defaults to $::fqdn
#
# [*proxy_server_cert_name*]
#
# [*upstream_port*]
#   TCP port to proxy to. Defaults to '80'
#
# [*default_server*]
#   Boolean. Adds the 'default_server' option to the listen statement.
#
# [*enabled*]
#   Boolean. Whether the site is enabled in the nginx sites-enabled directory.

define protoproxy::localssl(
    $server_name    = $::fqdn,
    $proxy_server_cert_name,
    $default_server = false,
    $enabled        = true,
    $upstream_port  = '80'
) {
    nginx::site { $name:
        content => template('protoproxy/localssl.erb'),
        enabled => $enabled
    }
}
