class profile::maps::tlsproxy(
    String $servicename      = lookup('profile::maps::tlsproxy::servicename'),
    String $ocsp_proxy       = lookup('http_proxy', {'default_value' => ''}),
){

    tlsproxy::localssl { $servicename:
        server_name     => $servicename,
        certs           => [$servicename],
        upstream_ports  => [6533],
        default_server  => true,
        do_ocsp         => false,
        ocsp_proxy      => $ocsp_proxy,
        ssl_ecdhe_curve => false,
        enable_http2    => false,
    }

    monitoring::service { 'maps-https':
        description   => 'Maps HTTPS',
        check_command => "check_https_url!${servicename}!/osm-intl/6/23/24.png",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Maps/RunBook',
    }

    ferm::service { 'maps-proxy-https':
        proto   => 'tcp',
        notrack => true,
        port    => '443',
    }
}
