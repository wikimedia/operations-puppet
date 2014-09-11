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
# [*server_name*]
#   Set servername
#
# [*sni_default*]
#   Boolean indicating if this is the SNI default cert
#

define protoproxy::localssl(
    $proxy_server_cert_name,
    $enabled       = true,
    $upstream_port = '80',
    $server_name   = $::fqdn,
    $sni_default   = false,
) {

    nginx::site { 'localssl':
        content => template('protoproxy/localssl.erb'),
        enabled => $enabled,
    }
}
