# a webserver for misc. static sites
class role::webserver_misc_static {

    include ::standard
    include ::profile::base::firewall

    include ::apache
    include ::apache::mod::authnz_ldap
    include ::apache::mod::rewrite
    include ::apache::mod::headers

    include ::profile::microsites::annualreport    # https://annual.wikimedia.org
    include ::profile::microsites::static_bugzilla # https://static-bugzilla.wikimedia.org
    include ::profile::microsites::transparency    # https://transparency.wikimedia.org
    include ::profile::microsites::wikibase        # https://wikiba.se
    include ::profile::microsites::research        # https://research.wikimedia.org (T183916)

    system::role { 'webserver_misc_static':
        description => 'WMF misc sites web server'
    }
}
