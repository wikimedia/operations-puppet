class role::pdfrender {
    $is_active = hiera('role::pdfrender::is_active', true)

    system::role { 'pdfrender':
        description => 'A PDF render service based on Electron',
    }

    $port = 5252

    class { '::pdfrender':
        port        => $port,
        no_browsers => 8,
        running     => $is_active,
    }

    ferm::service { "pdfrender_http_${port}":
        proto  => 'tcp',
        port   => $port,
        srange => '$DOMAIN_NETWORKS',
    }

}
