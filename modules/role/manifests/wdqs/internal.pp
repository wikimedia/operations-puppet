# = Class: role::wdqs::internal
#
# This class sets up Wikidata Query Service
class role::wdqs::internal {
    include ::standard
    include ::role::lvs::realserver
    include ::profile::base::firewall
    include ::profile::wdqs

    system::role { 'wdqs::internal':
        ensure      => 'present',
        description => 'Wikidata Query Service - internally available service',
    }
}
