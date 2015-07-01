# standard prod clusters' defaults for tlsproxy::localssl parameters
define role::cache::ssl::local(
    $certs,
    $do_ocsp=false,
    $server_name=$::fqdn,
    $server_aliases=[],
    $default_server=false
) {
    # Assumes that LVS service IPs are setup elsewhere

    tlsproxy::localssl { $name:
        certs           => $certs,
        upstream_port   => '80',
        default_server  => $default_server,
        server_name     => $server_name,
        server_aliases  => $server_aliases,
        do_ocsp         => $do_ocsp,
    }
}
