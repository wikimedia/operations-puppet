class profile::dumps::web::xmldumps {
    class {'::dumps::web::xmldumps':}

    ferm::service { 'xmldumps_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'xmldumps_https':
        proto => 'tcp',
        port  => '443',
    }
}
