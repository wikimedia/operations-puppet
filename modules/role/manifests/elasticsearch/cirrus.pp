# = Class: role::elasticsearch::cirrus
#
# This class sets up Elasticsearch specifically for CirrusSearch.
#
class role::elasticsearch::cirrus {
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::lvs::realserver
    include ::profile::elasticsearch::cirrus

    system::role { 'elasticsearch::cirrus':
        ensure      => 'present',
        description => 'elasticsearch cirrus',
    }

}
