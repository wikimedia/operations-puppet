# = Class: role::wdqs::internal
#
# This class sets up Wikidata Query Service
class role::wdqs::internal {
    include ::standard
    include ::role::lvs::realserver
    include ::profile::base::firewall
    require ::profile::wdqs::common
    require ::profile::wdqs::blazegraph
    require ::profile::wdqs::updater
    require ::profile::wdqs::gui

    system::role { 'wdqs::internal':
        ensure      => 'present',
        description => 'Wikidata Query Service - internally available service',
    }
}
