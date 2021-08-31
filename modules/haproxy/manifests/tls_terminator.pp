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
define haproxy::tls_terminator(
    Stdlib::Port $port,
    Stdlib::Unixpath $backend_socket,
    Array[Haproxy::Tlscertificate] $certificates,
    Stdlib::Unixpath $crt_list_path = '/etc/haproxy/crt-list.cfg',
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
