# let users publish their own HTML in their home dirs
class role::microsites::peopleweb {
    include profile::base::production
    include profile::firewall
    include profile::backup::host
    include profile::microsites::peopleweb
    include profile::tlsproxy::envoy # TLS termination
    include profile::prometheus::apache_exporter
}
