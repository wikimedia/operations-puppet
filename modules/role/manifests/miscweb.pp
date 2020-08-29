# a webserver for misc. apps and static sites
class role::miscweb {

    system::role { 'miscweb':
        description => 'WMF misc apps and sites web server'
    }

    include ::profile::standard                    # base tools
    include ::profile::base::firewall              # firewalling
    include ::profile::backup::host                # Bacula backups 
    include ::profile::misc_apps::httpd            # common webserver setup
    include ::profile::misc_apps::rsync            # copy data for migrations
    include ::profile::tlsproxy::envoy             # TLS termination

    include ::profile::wikimania_scholarships      # https://scholarships.wikimedia.org
    include ::profile::iegreview                   # https://iegreview.wikimedia.org
    include ::profile::racktables                  # https://racktables.wikimedia.org
    include ::profile::microsites::annualreport    # https://annual.wikimedia.org
    include ::profile::microsites::static_bugzilla # https://static-bugzilla.wikimedia.org
    include ::profile::microsites::static_rt       # https://static-rt.wikimedia.org
    include ::profile::microsites::transparency    # https://transparency.wikimedia.org
    include ::profile::microsites::research        # https://research.wikimedia.org (T183916)
    include ::profile::microsites::design          # https://design.wikimedia.org (T185282)
    include ::profile::microsites::sitemaps        # https://sitemaps.wikimedia.org
    include ::profile::microsites::bienvenida      # https://bienvenida.wikimedia.org (T207816)
    include ::profile::microsites::wikiworkshop    # https://wikiworkshop.org (T242374)
    include ::profile::microsites::static_codereview # https://static-codereview.wikimedia.org (T243056)
}
