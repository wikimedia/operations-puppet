class profile::dumps::web::active_xmldumps {
    class {'::dumps::web::active_xmldumps':}

    ferm::service { 'xmldumps_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'xmldumps_https':
        proto => 'tcp',
        port  => '443',
    }

    monitoring::service { 'http':
        description   => 'HTTP',
        check_command => 'check_http'
    }

    # TODO: move hiera lookup to parameter of this class
    if hiera('do_acme', true) {
        monitoring::service { 'https':
            description   => 'HTTPS',
            check_command => 'check_ssl_http_letsencrypt!dumps.wikimedia.org',
        }
    }
}
