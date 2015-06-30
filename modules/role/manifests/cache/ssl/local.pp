# Helper for standard prod clusters' use of tlsproxy::localssl
define role::cache::ssl::local($certname, $do_ocsp=false, $server_name=$::fqdn, $server_aliases=[], $default_server=false) {
    # Assumes that LVS service IPs are setup elsewhere

    tlsproxy::localssl { $name:
        proxy_server_cert_name => $certname,
        upstream_port          => '80',
        default_server         => $default_server,
        server_name            => $server_name,
        server_aliases         => $server_aliases,
        do_ocsp                => $do_ocsp,
    }
}
