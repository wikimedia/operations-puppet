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
#   Exactly one instance should have this set to true.
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

    # Ensure that exactly one definition exists with default_server = true
    # if multiple defines have default_server set to true, this
    # resource will conflict.
    if $default_server {
        notify { 'protoproxy localssl default_server':
            message => "protoproxy::localssl instance $title with server name $server_name is the default server."
        }
    }

    nginx::site { $name:
        require => Notify['protoproxy localssl default_server'],    # Ensure a default_server has been defined
        content => template('protoproxy/localssl.erb'),
        enabled => $enabled
    }
}
