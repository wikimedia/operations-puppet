# = Class: role::elasticsearch::cirrus
#
# This class sets up Elasticsearch specifically for CirrusSearch.
#
class role::elasticsearch::cirrus {
    include ::profile::standard
    include ::profile::base::firewall
    include ::role::lvs::realserver
    include ::profile::elasticsearch::cirrus
    include ::profile::mjolnir::kafka_bulk_daemon
    include ::profile::mjolnir::kafka_msearch_daemon

    system::role { 'elasticsearch::cirrus':
        ensure      => 'present',
        description => 'elasticsearch cirrus',
    }

}
