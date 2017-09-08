# serve html dumps generated from revision content in restbase
class role::dumps::web::htmldumps {

    system::role { 'dumps::web::htmldumps': description => 'Web server for html dumps' }

    include ::standard
    include ::profile::dumps::web::htmldumps
    include ::base::firewall

    ferm::service { 'html_dumps_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'html_dumps_https':
        proto => 'tcp',
        port  => '443',
    }
}
