# https://wikitech.wikimedia.org/wiki/RT
class role::requesttracker {
    include profile::base::production
    include profile::firewall
    include profile::requesttracker
    include profile::tlsproxy::envoy # TLS termination
    include profile::prometheus::apache_exporter
}
