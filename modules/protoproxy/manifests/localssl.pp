# == Define: protoproxy::localssl
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
# [*proxy_server_cert_name*]
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

define protoproxy::localssl(
    $proxy_server_cert_name,
    $server_name    = $::fqdn,
    $server_aliases = [],
    $default_server = false,
    $upstream_port  = '80',
    $do_ocsp        = false
) {
    require ::sslcert

    # Ensure that exactly one definition exists with default_server = true
    # if multiple defines have default_server set to true, this
    # resource will conflict.
    if $default_server {
        notify { 'protoproxy localssl default_server':
            message => "protoproxy::localssl instance ${title} with server name ${server_name} is the default server."
        }
    }

    # for localssl.erb below
    if os_version('debian >= jessie') {
        $ssl_protos = 'ssl spdy'
    }
    else {
        $ssl_protos = 'ssl'
    }

    if $do_ocsp {
        include ::protoproxy::ocsp_updater

        certpath = "/etc/ssl/localcerts/${proxy_server_cert_name}.crt"
        output = "/var/cache/ocsp/${proxy_server_cert_name}.ocsp"
        proxy = "webproxy.${::site}.wmnet:8080"

        exec { "${title}-create-ocsp":
            command => "/usr/local/sbin/update-ocsp -c $cert -o $output -p $proxy",
            creates => $output,
            require => Sslcert::Certificate[$proxy_server_cert_name],
            before  => Service['nginx']
        }
    }

    nginx::site { $name:
        require => Notify['protoproxy localssl default_server'],    # Ensure a default_server has been defined
        content => template('protoproxy/localssl.erb')
    }
}
