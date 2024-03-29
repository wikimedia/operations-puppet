# a webserver for misc. apps and static sites
class role::miscweb {

    system::role { 'miscweb':
        description => 'WMF misc apps and sites web server'
    }

    include profile::base::production            # base tools
    include profile::firewall                    # firewalling
    include profile::backup::host                # Bacula backups 
    include profile::miscweb::httpd              # common webserver setup
    include profile::miscweb::rsync              # copy data for migrations
    include profile::tlsproxy::envoy             # TLS termination
    include profile::prometheus::apache_exporter # dashboard data

    include profile::microsites::static_rt       # https://static-rt.wikimedia.org
    include profile::microsites::security        # https://security.wikimedia.org (T257830)
    include profile::microsites::query_service   # parts of https://query.wikidata.org (T266702)
    include profile::microsites::os_reports      # https://os-reports.wikimedia.org
    include profile::microsites::monitoring      # Contains blackbox checks for miscweb services on Kubernetes (T300171)
}
