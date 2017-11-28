# serve dumps of revision content from restbase, in html format
class role::dumps::web::htmldumps {

    system::role { 'role::dumps::web::htmldumps': description => 'web server of HTML format dumps' }

    include ::standard
    include ::profile::dumps::web::htmldumps
    include ::profile::base::firewall

    ferm::service { 'html_dumps_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'html_dumps_https':
        proto => 'tcp',
        port  => '443',
    }
}
