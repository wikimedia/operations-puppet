# = Class: role::elasticsearch::relforge
#
# This class sets up Elasticsearch for relevance forge.
#
class role::elasticsearch::relforge {
    include profile::base::production
    include profile::firewall
    include profile::elasticsearch::relforge
    include profile::kibana
    include profile::logstash::gelf_relay
}
