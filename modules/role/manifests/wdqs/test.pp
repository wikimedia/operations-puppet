# = Class: role::wdqs::test
#
# This class sets up Wikidata Query Service
class role::wdqs::test {
    include ::profile::standard
    include ::profile::base::firewall
    require ::profile::query_service::common
    require ::profile::query_service::blazegraph
    require ::profile::query_service::categories
    require ::profile::query_service::updater
    require ::profile::query_service::gui

    system::role { 'wdqs::test':
        ensure      => 'present',
        description => 'Wikidata Query Service - test cluster',
    }
}
