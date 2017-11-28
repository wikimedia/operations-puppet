class profile::pdfrender(
    $is_active = hiera('profile::pdfrender::is_active', true)
) {

    $port = 5252

    class { '::pdfrender':
        port        => $port,
        no_browsers => 4,
        running     => $is_active,
    }

    ferm::service { "pdfrender_http_${port}":
        proto  => 'tcp',
        port   => $port,
        srange => '$DOMAIN_NETWORKS',
    }

}
