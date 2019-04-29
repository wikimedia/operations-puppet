# = Class: role::wdqs::labs
#
# This class sets up Wikidata Query Service on Cloud VPS
#
# filtertags: labs-project-wikidata-query
class role::wdqs::labs () {
    require role::labs::lvm::srv

    include ::profile::standard
    include ::profile::base::firewall
    require ::profile::wdqs::common
    require ::profile::wdqs::blazegraph
    require ::profile::wdqs::updater
    require ::profile::wdqs::gui

    system::role { 'wdqs':
        ensure      => 'present',
        description => 'Wikidata Query Service',
    }
}
