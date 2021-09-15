# = Class: role::elasticsearch::cirrus
#
# This class sets up Elasticsearch specifically for CirrusSearch.
#
class role::elasticsearch::cirrus {
    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::lvs::realserver
    include ::profile::elasticsearch::cirrus

    # limit initial rollout of gelf_relay to elastic1049
    if $::hostname == 'elastic1049' {
        include ::profile::logstash::gelf_relay
    }

    system::role { 'elasticsearch::cirrus':
        ensure      => 'present',
        description => 'elasticsearch cirrus',
    }

}
