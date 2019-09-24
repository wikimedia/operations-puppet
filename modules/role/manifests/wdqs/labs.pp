# = Class: role::wdqs::labs
#
# This class sets up Wikidata Query Service on Cloud VPS
#
# filtertags: labs-project-wikidata-query
class role::wdqs::labs () {
    require role::labs::lvm::srv

    include ::profile::standard
    include ::profile::base::firewall
    require ::profile::query_service::common
    require ::profile::query_service::blazegraph
    require ::profile::query_service::updater
    require ::profile::query_service::gui

    system::role { 'wdqs':
        ensure      => 'present',
        description => 'Wikidata Query Service',
    }
}
