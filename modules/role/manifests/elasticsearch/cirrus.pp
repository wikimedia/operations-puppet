# = Class: role::elasticsearch::cirrus
#
# This class sets up Elasticsearch specifically for CirrusSearch.
#
class role::elasticsearch::cirrus {
    include ::standard
    include ::base::firewall
    include ::role::lvs::realserver
    include ::profile::elasticsearch

    system::role { 'elasticsearch::cirrus':
        ensure      => 'present',
        description => 'elasticsearch cirrus',
    }

}
