# @summary
#   Configure HAProxy to be a TLS proxy to local services listening on UNIX sockets
#
# @param port
#   TCP port to listen on with HTTPS support
# @param backend_socket
#   Absolute path to the UNIX socket acting as backend service
# @param certificates
#   List of TLS certificates used to listen on $port
# @param crt_list_file
#   Path used for the crt-list file. Defaults to /etc/haproxy/crt-list.cfg
# @param tls_ciphers
#   Allowed ciphersuites for <= TLSv1.2
# @param tls13_ciphers
#   Allowed ciphersuites for TLSv1.3
# @param timeout
#   timeout configuration. See Haproxy::Timeout for more details
# @param h2settings
#   H2 performance tuning settings. See Haproxy::H2settings for more details
# @param min_tls_version
#   minimum supported TLS version. Defaults to TLSv1.2
# @param max_tls_version
#   minimum supported TLS version. Defaults to TLSv1.3
# @param ecdhe_curves
#   List of supported ECHDE curves. Defaults to X25519, P-256
# @param alpn
#   List of Application layer protocols (ALPN) supported. Defaults to h2, http/1.1
define haproxy::tls_terminator(
    Stdlib::Port $port,
    Stdlib::Unixpath $backend_socket,
    Array[Haproxy::Tlscertificate] $certificates,
    String $tls_ciphers,
    String $tls13_ciphers,
    Haproxy::Timeout $timeout,
    Haproxy::H2settings $h2settings,
    Haproxy::Tlsversion $min_tls_version = 'TLSv1.2',
    Haproxy::Tlsversion $max_tls_version = 'TLSv1.3',
    Haproxy::Ecdhecurves $ecdhe_curves = ['X25519', 'P-256'],
    Haproxy::Alpn $alpn = ['h2', 'http/1.1'],
    Stdlib::Unixpath $crt_list_path = '/etc/haproxy/crt-list.cfg',
    Optional[Stdlib::Unixpath] $tls_ticket_keys_path = undef,
    Optional[Haproxy::Proxyprotocol] $proxy_protocol = undef,
) {
    # First of all, we can't configure a tls terminator if haproxy is not installed.
    if !defined(Class['haproxy']) {
        fail('haproxy::tls_terminator should only be used once the haproxy class is declared.')
    }

    file { $crt_list_path:
        mode    => '0444',
        content =>  template('haproxy/crt-list.cfg.erb'),
        notify  =>  Service['haproxy'],
    }

    haproxy::site { $title:
        content => template('haproxy/tls_terminator.cfg.erb'),
    }
}
