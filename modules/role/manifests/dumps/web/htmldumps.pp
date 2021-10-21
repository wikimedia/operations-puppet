# serve dumps of revision content from restbase, in html format
class role::dumps::web::htmldumps {

    system::role { 'role::dumps::web::htmldumps': description => 'web server of HTML format dumps' }

    include profile::base::production
    include profile::base::firewall
    include profile::nginx
    include profile::dumps::web::htmldumps
}
