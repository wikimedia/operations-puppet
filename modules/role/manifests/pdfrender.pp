class role::pdfrender {

    system::role { 'role::pdfrender':
        description => 'A PDF render service based on Electron',
    }

    include ::pdfrender

    ferm::service { 'pdfrender_http_5252':
        proto  => 'tcp',
        port   => '5252',
        srange => '$DOMAIN_NETWORKS',
    }

}

