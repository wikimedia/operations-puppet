class profile::maps::tlsproxy(
    $servicename = hiera('profile::maps::tlsproxy::servicename'),
) {
    tlsproxy::localssl { $servicename:
        server_name    => $servicename,
        certs          => [$servicename],
        upstream_ports => [6533],
        default_server => true,
        do_ocsp        => false,
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
