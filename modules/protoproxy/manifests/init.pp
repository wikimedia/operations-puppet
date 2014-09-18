# vim:sw=4:ts=4:et:

# == Definition: protoproxy
#
# This definition creates a nginx site. The parameters are merely expanded in
# the templates which has all of the logic.
#
# The resulting site will always listen on the server real IP.
#
# === Parameters:
#
# [*proxy_addresses*]
# Additional IP address to listen to. IPv6 addresses will be skipped
# unless *IpV6_enabled* is true. The hash first level is made of sites
# entries, the IP are passed as an array.
# This is optional, the site will always listen on the server real IP.
# Defaults to {}
#
# [*proxy_server_name*]
#
# [*proxy_server_cert_name*]
#
# [*proxy_backend*]
#
# [*proxy_listen_flags*]
# Defaults to ''
#
# [*proxy_port*]
# The TCP port to listen on.
# Defaults to '80'
#
# [*ipV6_enabled*]
# Whether to have the site listen on IPv6 addresses set via *proxy_addresses*
# Defaults to false
#
# [*ssl_backend*]
# Defaults to {}
#
# === Example:
#
#  protoproxy{ 'bits.wikimedia.org':
#    proxy_addresses => {
#      'pmtpa' => [ '192.0.2.1' ],
#    },
#    proxy_server_name      => 'bits.wikimedia.org',
#    proxy_server_cert_name => 'unified.wikimedia.org',
#    proxy_backend => {
#     'pmtpa' => {'primary' => 'apaches.wmnet' },
#    },
#    ipv6_enabled => false
#  }
#
define protoproxy(
    $proxy_server_name,
    $proxy_server_cert_name,
    $proxy_backend,
    $proxy_addresses={},
    $proxy_listen_flags='',
    $proxy_port='80',
    $ipv6_enabled=false,
    $ssl_backend={},
) {
    nginx::site { $name:
        content  => template('protoproxy/proxy.erb')
    }
}
