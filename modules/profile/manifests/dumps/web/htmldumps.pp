class profile::dumps::web::htmldumps {
    class {'::dumps::web::htmldumps': htmldumps_server => 'francium.eqiad.wmnet'}

    ferm::service { 'html_dumps_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'html_dumps_https':
        proto => 'tcp',
        port  => '443',
    }

}
