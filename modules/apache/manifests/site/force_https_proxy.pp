# == Define apache::site::force_https_proxy
# Creates a transparent reverse http proxy that force redirects to https.
# This does not do any https handling.  Instead, it should be used
# as a generic way to force redirect a direct incoming http request to https,
# and to transparently proxy decrypted https requests
# (those where X-Forwarded-Proto=https) to their destination.
#
# This requires that something is serving
# https requests at https://<HTTP_HOST>.
#
# == Parameters
# $server_name              - Proxy VirtualHost ServerName.                 Default: $fqdn
# $listen_port              - Proxy VirtualHost ListenPort.                 Default: 80
# server_alias              - Array of ServerAliases for this VirtualHost.  Default undef
# $destination_host         - Host on which your service is running.        Default: localhost
# $destination_port         - Port on which your service is listening.      Default: 81
#
define apache::site::force_https_proxy (
    $server_name      = $::fqdn,
    $listen_port      = 80,
    $server_alias     = undef,
    $destination_host = 'localhost',
    $destination_port = 81,
) {
    if $listen_port != 80 {
        # Add apache conf to listen on this port
        apache::conf { "${title}-force-https-proxy-port":
            ensure   => $ensure,
            content  => "Listen ${listen_port}\n",
            before   => Apache::Site["${title}-force-https-proxy"],
        }
    }

    apache::site { "${title}-force-https-proxy":
        content => 'apache/templates/force-https-proxy.erb',
    }
}
