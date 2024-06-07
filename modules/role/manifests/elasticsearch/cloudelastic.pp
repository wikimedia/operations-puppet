# = Class: role::elasticsearch::cloudelastic
#
# This class sets up Elasticsearch specifically for CirrusSearch on cloudelastic nodes.
#
class role::elasticsearch::cloudelastic {
    include profile::base::production
    include profile::firewall
    include profile::elasticsearch::cirrus
    include profile::elasticsearch::monitor::base_checks
    include profile::lvs::realserver
    include profile::logstash::gelf_relay
}
