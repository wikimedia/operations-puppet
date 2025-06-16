# a webserver for misc. apps and static sites
class role::miscweb {
    include profile::base::production            # base tools
    include profile::firewall                    # firewalling
    include profile::backup::host                # Bacula backups
    include profile::miscweb::httpd              # common webserver setup
    include profile::tlsproxy::envoy             # TLS termination
    include profile::prometheus::apache_exporter # dashboard data

    include profile::microsites::monitoring      # Contains blackbox checks for miscweb services on Kubernetes (T300171)
}
