# == Class archiva::proxy
# Sets up a simple nginx reverse proxy.
# This must be included on the same node as the archiva server.
#
# This depends on the nginx, ferm, and sslcert modules from WMF operations/puppet/modules.
#
# == Parameters
# $ssl_enabled        - If true, this proxy will do SSL and force redirect to HTTPS.  Default: true
#
# $certificate_name   - Name of certificate.  If this is anything but 'ssl-cert-snakeoil',
#                       sslcert::certificate will be called, and the certificate file will be
#                       assumed to be in /etc/ssl/localcert.  If this is 'ssl-cert-snakeoil',
#                       the snakeoil certificate will be used.  It is expected to be found at
#                       /etc/ssl/certs/ssl-cert-snakeoil.pem.  Default: archiva.wikimedia.org
#
class archiva::proxy(
    $ssl_enabled      = true,
    $certificate_name = 'archiva.wikimedia.org',
) {
    Class['::archiva'] -> Class['::archiva::proxy']

    # Set up simple Nginx reverse proxy to $archiva_port.
    class { '::nginx': }

    # $archiva_server_properties and
    # $ssl_server_properties will be concatenated together to form
    # a single $server_properties array for proxy.nginx.erb
    # nginx site template.
    $archiva_server_properties = [
        # Need large body size to allow for .jar deployment.
        'client_max_body_size 256M;',
        # Archiva sometimes takes a long time to respond.
        'proxy_connect_timeout 600s;',
        'proxy_read_timeout 600s;',
        'proxy_send_timeout 600s;',
    ]

    if $ssl_enabled {
        $listen = '443 ssl'

        # Install the certificate if it is not the snakeoil cert
        if $certificate_name != 'ssl-cert-snakeoil' {
            sslcert::certificate { $certificate_name:
                before => Nginx::Site['archiva'],
            }
        }

        $ssl_certificate_chained = $certificate_name ? {
            'ssl-cert-snakeoil' => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
            default             => "/etc/ssl/localcerts/${certificate_name}.chained.crt",
        }
        $ssl_certificate_key = "/etc/ssl/private/${certificate_name}.key"

        # Use puppet's stupidity to flatten these into a single array.
        $server_properties = [
            $archiva_server_properties,
            ssl_ciphersuite('nginx', 'compat'),
            [
                "ssl_certificate     ${ssl_certificate_chained};",
                "ssl_certificate_key ${ssl_certificate_key};",
            ],
        ]

    }
    else {
        $listen = 80
        $server_properties = $archiva_server_properties
    }

    $proxy_pass = "http://127.0.0.1:${::archiva::port}/"

    nginx::site { 'archiva':
        content => template('archiva/proxy.nginx.erb'),
    }
}
