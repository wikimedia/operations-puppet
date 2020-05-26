# = Class: role::wdqs::internal
#
# This class sets up Wikidata Query Service for internal prod cluster use
# cases.
class role::wdqs::internal {
    # Standard for all roles
    include ::profile::standard
    include ::profile::base::firewall
    # Standard wdqs installation
    require ::profile::query_service::common
    require ::profile::query_service::blazegraph
    require ::profile::query_service::categories
    require ::profile::query_service::updater
    require ::profile::query_service::gui
    # Production specific profiles
    include ::profile::lvs::realserver

    system::role { 'wdqs::internal':
        ensure      => 'present',
        description => 'Wikidata Query Service - internally available service',
    }
}
