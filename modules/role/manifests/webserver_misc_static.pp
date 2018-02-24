# a webserver for misc. static sites
class role::webserver_misc_static {

    system::role { 'webserver_misc_static':
        description => 'WMF misc sites web server'
    }

    include ::standard
    include ::profile::base::firewall
    include ::profile::microsites::httpd

    include ::profile::microsites::annualreport    # https://annual.wikimedia.org
    include ::profile::microsites::static_bugzilla # https://static-bugzilla.wikimedia.org
    include ::profile::microsites::transparency    # https://transparency.wikimedia.org
    include ::profile::microsites::wikibase        # https://wikiba.se
    include ::profile::microsites::research        # https://research.wikimedia.org (T183916)
    include ::profile::microsites::design          # https://design.wikimedia.org (T185282)

}
