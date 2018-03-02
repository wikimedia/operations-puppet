# = Class: role::wdqs
#
# This class sets up Wikidata Query Service
class role::wdqs_internal {
    include ::standard
    include ::base::firewall
    include ::role::lvs::realserver
    include ::profile::wdqs

    system::role { 'wdqs-internal':
        ensure      => 'present',
        description => 'Wikidata Query Service - internally available service',
    }
}
