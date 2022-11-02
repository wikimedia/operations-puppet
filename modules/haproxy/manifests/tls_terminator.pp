# @summary
#   Configure HAProxy to be a TLS proxy to local services listening on UNIX sockets
#
# @param port
#   TCP port to listen on with HTTPS support
# @param backend_socket
#   Absolute path to the UNIX socket acting as backend service
# @param certificates
#   List of TLS certificates used to listen on $port
# @param crt_list_path
#   Path used for the crt-list file. Defaults to /etc/haproxy/crt-list.cfg
# @param tls_dh_param_path
#   Path used for the DH param file. Defaults to /etc/ssl/dhparam.pem
# @param tls_cachesize
#   Sets the size of the global SSL session cache, in a number of blocks. A block
#   is large enough to contain an encoded session without peer certificate.
#   Defaults to 20000
# @param tls_session_lifetime
#   Sets how long a cached SSL session may remain valid.
#   Defaults to 300 seconds
# @param http_reuse
#   HTTP connection reuse policy.
#   Defaults to safe
# @param numa_iface
#   Network interface used to bound HAProxy to a NUMA node.
#   Defaults to lo
# @param haproxy_version
#   HAProxy version being used.
#   Defaults to haproxy24
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
# @param lua_scripts
#   List of lua scripts to be loaded
# @param vars
#   List of variables to set based on HTTP request|response data
# @param acls
#   List of ACLs. They can be used to conditionally remove HTTP headers
# @param add_headers
#   List of headers to add on HTTP requests or responses
# @param del_headers
#   List of headers to remove on HTTP requests or respones
# @param prometheus_port
#   Port to expose stats and prometheus metrics. Requires HAProxy >= 2.0
# @param sticktables
#   List of pseudo-backends to create for tracking stats with stick-tables.
# @param stickycounters
#   Array of Stickycounter objects to link requests to stick-tables.
define haproxy::tls_terminator(
    Stdlib::Port $port,
    Array[Haproxy::Backend] $backends,
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
    Stdlib::Unixpath $tls_dh_param_path = '/etc/ssl/dhparam.pem',
    Integer[0] $tls_cachesize = 20000,
    Integer[0] $tls_session_lifetime = 300,
    Haproxy::Httpreuse $http_reuse = 'safe',
    String $numa_iface = 'lo',
    Haproxy::Version $haproxy_version = 'haproxy24',
    Optional[Stdlib::Unixpath] $tls_ticket_keys_path = undef,
    Optional[Haproxy::Proxyprotocol] $proxy_protocol = undef,
    Optional[Array[Stdlib::Unixpath]] $lua_scripts = undef,
    Optional[Array[Haproxy::Var]] $vars = undef,
    Optional[Array[Haproxy::Acl]] $acls = undef,
    Optional[Array[Haproxy::Header]] $add_headers = undef,
    Optional[Array[Haproxy::Header]] $del_headers = undef,
    Optional[Stdlib::Port] $prometheus_port = undef,
    Optional[Array[Haproxy::Sticktable]] $sticktables = undef,
    Optional[Array[Haproxy::Stickycounter]] $stickycounters = undef,
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
