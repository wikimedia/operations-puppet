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
#   Optional - specify either this or cfssl_paths.
#   Array of certs, normally just one.  If more than one, special patched nginx
#   support is required.  This is intended to support duplicate keys with
#   differing crypto (e.g. ECDSA + RSA).
#
# [*certs_active*]
#   Optional - if "certs" above is used, this defines the subset of the certs to
#   actually configure on the server.  This allows for additional certs to be
#   fully deployed and OCSP stapled (ready for use), which aren't actually used
#   to serve traffic.  Defaults to the entire set from "certs".
#
# [*acme_chief*]
#   Optional - specify either this or cfssl_paths.
#   If true, download, and potentially use, certificates from acme-chief.
#   If $certs is empty, acme-chief certificates will be used to serve traffic.
#   When used in conjunction with certs, acme-chief certificate will be deployed on
#   the server but certs specified in $certs will be used to serve traffic

# [*acme_certname*]
#   Optional - specify this if title of the resource and the acme-chief certname differs.
#
# [*upstream_ports*]
#   TCP ports array to proxy to. Defaults to ['80']
#
# [*tls_port*]
#   TCP port to listen on as HTTPS.  This listener will proxy all traffic
#   to @upsteam_ports. Default is 443.
#
# [*redir_port*]
#   TCP port to listen on as plain HTTP.  This listener will redirect GET/HEAD
#   to HTTPS with 301 and deny all other methods with 403.  It does not proxy
#   any traffic. Default is undefined.
#
# [*default_server*]
#   Boolean. Adds the 'default_server' option to the listen statement.
#   Exactly one instance should have this set to true.
#
# [*do_ocsp*]
#   Boolean. Sets up OCSP Stapling for this server.  This both enables the
#   correct configuration directives in the site's nginx config file as well
#   as creates the OCSP data file itself and ensures a cron is running to
#   keep it up to date.  Does not work for ACME (letsencrypt) yet!
#
# [*access_log*]
#   Boolean. If true, sets up the access log for the localssl virtualhost.
#   Do NOT enable on the cache nodes. Defaults to false
#
# [*keepalive_timeout*]
#   Timeout (in seconds) for HTTP keepalive connections. The zero value disables
#   keep-alive client connections. Defaults to 60 seconds.
#
# [*keepalive_requests*]
#   The maximum number of requests that can be served through one keep-alive
#   connection. After the maximum number of requests are made, the connection
#   is closed. Defaults to 100 requests.
#
# [*read_timeout*]
#   Timeout (in seconds) for reading a response from the proxied server. The
#   timeout is set only between two successive read operations, not for the
#   transmission of the whole response. If the proxied server does not transmit
#   anything within this time, the connection is closed.  It should be set to
#   a value that corresponds to the backend timeout. Defaults to 180 seconds.
#
# [*only_get_requests*]
#  Deny all non-GET requests to this endpoint. Defaults to false.
#
# [*ssl_ecdhe_curve*]
#  Whether or not the nginx package has support for $ssl_ecdhe_curve. Defaults
#  to true.
# [*enable_http2*]
#  Whether to enable http2 or not. Defaults to false. It's best to only enable
#  this on public facing instances since in internal services (even if proxied
#  by the edge cache) it adds 1 more moving part without providing considerable
#  benefits
# [*cfssl_certs*]
#   A hash of paths pointing to ssl certificate files,  created by profile::pki::get_cert
#   if this is present it takes precedence

define tlsproxy::localssl(
    Array                             $certs              = [],
    Array                             $certs_active       = [],
    Boolean                           $acme_chief         = false,
    String[1]                         $acme_certname      = $title,
    Stdlib::Host                      $server_name        = $::fqdn,
    Array[Stdlib::Host]               $server_aliases     = [],
    Boolean                           $default_server     = false,
    Stdlib::IP::Address               $upstream_ip        = $::ipaddress,
    Array[Stdlib::Port]               $upstream_ports     = [80],
    Stdlib::Port                      $tls_port           = 443,
    Optional[Stdlib::Port]            $redir_port         = undef,
    Boolean                           $do_ocsp            = false,
    Boolean                           $skip_private       = false,
    Boolean                           $access_log         = false,
    Integer                           $keepalive_timeout  = 60,
    Integer                           $keepalive_requests = 100,
    Integer                           $read_timeout       = 180,
    String                            $ocsp_proxy         = '',
    Boolean                           $only_get_requests  = false,
    Boolean                           $ssl_ecdhe_curve    = true,
    Boolean                           $enable_http2       = false,
    Hash[String[1], Stdlib::Unixpath] $cfssl_paths        = {}
) {
    if $cfssl_paths.empty and $certs.empty and !acme_chief {
        fail('Must provide exactly one of certs, cfssl_paths or acme_chief')
    }

    if $redir_port != undef and $tls_port != 443 {
        fail('http -> https redirect only works with default 443 HTTPS port.')
    }

    # TODO: move this define to the profile module too?
    require ::profile::tlsproxy::instance

    $nginx_proxy_request_buffering = lookup('tlsproxy::localssl::proxy_request_buffering', {'default_value' => 'on'})
    # Maximum number of pending TCP Fast Open requests before falling back to
    # regular 3WHS. https://tools.ietf.org/html/rfc7413#section-5.1
    $fastopen_pending_max = lookup('tlsproxy::localssl::fastopen_pending_max', {'default_value' => 150})

    # Ensure that exactly one definition exists with default_server = true
    # for a given port. If multiple defines on the same port have default_server
    # set to true this resource will conflict.
    # we configure this resource as an exec which does nothing and should
    # never trigger.  We define the resource so it still allows us to catch multiple
    # definitions of default_server but shouldn't show as a change in puppet reporting
    if $default_server {
        exec { "tlsproxy localssl default_server on port ${tls_port}":
            command     => '/bin/true',
            onlyif      => '/bin/false',
            refreshonly => true,
        }
    }

    if !empty($certs) and !empty($certs_active) {
        # Ideally, we'd sanity-check that active is a subset of certs, too
        $certs_nginx = $certs_active
    } else {
        $certs_nginx = $certs
    }

    $certs.each |String $cert| {
        if !defined(Sslcert::Certificate[$cert]) {
            sslcert::certificate { $cert:
                skip_private => $skip_private,
                before       => Service['nginx'],
            }
        }
    }

    if $do_ocsp {
        require tlsproxy::ocsp

        $certs.each |String $cert| {
            if !defined(Sslcert::Ocsp::Conf[$cert]) {
                sslcert::ocsp::conf { $cert:
                    proxy  => $ocsp_proxy,
                    before => [Service['nginx'], Exec['nginx-reload']],
                }
            }
        }
    }

    if $acme_chief {
        if !defined(Acme_chief::Cert[$acme_certname]) {
            acme_chief::cert { $acme_certname:
                puppet_svc => 'nginx',
            }
        }
        if $do_ocsp {
            File["/etc/acmecerts/${acme_certname}"] ~> Exec['nginx-reload']
        }
    }
    unless $cfssl_paths.empty {
        File[$cfssl_paths] ~> Exec['nginx-reload']
    }

    # used in localssl.erb to template upstream definition name
    $basename = regsubst($title, '[\W_]', '-', 'G')

    nginx::site { $name:
        require => Exec["tlsproxy localssl default_server on port ${tls_port}"],    # Ensure a default_server has been defined
        content => template('tlsproxy/localssl.erb')
    }
}
