# = Class: role::wdqs::internal
#
# This class sets up Wikidata Query Service
class role::wdqs::internal {
    include ::profile::standard
    include ::profile::lvs::realserver
    include ::profile::base::firewall
    require ::profile::query_service::common
    require ::profile::query_service::blazegraph
    require ::profile::query_service::categories
    require ::profile::query_service::updater
    require ::profile::query_service::gui

    system::role { 'wdqs::internal':
        ensure      => 'present',
        description => 'Wikidata Query Service - internally available service',
    }
}
