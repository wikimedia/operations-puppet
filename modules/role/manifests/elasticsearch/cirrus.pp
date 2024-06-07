# = Class: role::elasticsearch::cirrus
#
# This class sets up Elasticsearch specifically for CirrusSearch.
#
class role::elasticsearch::cirrus {
    include profile::base::production
    include profile::firewall
    include profile::lvs::realserver
    include profile::elasticsearch::cirrus
    include profile::logstash::gelf_relay
}
