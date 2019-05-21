# serve dumps of revision content from restbase, in html format
class role::dumps::web::htmldumps {

    system::role { 'role::dumps::web::htmldumps': description => 'web server of HTML format dumps' }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log
    include ::profile::dumps::web::htmldumps
}
