# == Define: tlsproxy::localssl
#
# This definition creates a SSL proxy to localhost, using an Nginx site.
#
# === Parameters:
# [*server_name*]
#   Server name, used e.g. for SNI. Defaults to $::fqdn
#
# [*server_aliases*]
#   List of server aliases, host names also served.
#
# [*certs*]
#   Required - Array of certs, normally just one.  If more than one, special
#   patched nginx support is required, and the OCSP/Issuer/Subject/SAN info
#   should be identical in all certs.  This is intended to support duplicate
#   keys with differing crypto (e.g. ECDSA + RSA).
#
# [*upstream_port*]
#   TCP port to proxy to. Defaults to '80'
#
# [*default_server*]
#   Boolean. Adds the 'default_server' option to the listen statement.
#   Exactly one instance should have this set to true.
#
# [*do_ocsp*]
#   Boolean. Sets up OCSP Stapling for this server.  This both enables the
#   correct configuration directives in the site's nginx config file as well
#   as creates the OCSP data file itself and ensures a cron is running to
#   keep it up to date.

define tlsproxy::localssl(
    $certs,
    $server_name    = $::fqdn,
    $server_aliases = [],
    $default_server = false,
    $upstream_port  = '80',
    $do_ocsp        = false,
    $skip_private   = false,
) {
    require tlsproxy::instance

    # Ensure that exactly one definition exists with default_server = true
    # if multiple defines have default_server set to true, this
    # resource will conflict.
    if $default_server {
        notify { 'tlsproxy localssl default_server':
            message => "tlsproxy::localssl instance ${title} with server name ${server_name} is the default server."
        }
    }

    sslcert::certificate { $certs:
        skip_private => $skip_private,
    }

    if $do_ocsp {
        include tlsproxy::ocsp

        sslcert::ocsp::conf { $title:
            proxy  => "webproxy.${::site}.wmnet:8080",
            certs  => $certs,
            before => Service['nginx'],
        }
    }

    nginx::site { $name:
        require => Notify['tlsproxy localssl default_server'],    # Ensure a default_server has been defined
        content => template('tlsproxy/localssl.erb')
    }
}
