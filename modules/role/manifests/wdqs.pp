# = Class: role::wdqs
#
# This class sets up Wikidata Query Service
class role::wdqs {
    include ::profile::standard
    include ::role::lvs::realserver
    include ::profile::base::firewall
    require ::profile::wdqs::common
    require ::profile::wdqs::blazegraph
    require ::profile::wdqs::updater
    require ::profile::wdqs::gui

    system::role { 'wdqs':
        ensure      => 'present',
        description => 'Wikidata Query Service - publicly available service',
    }
}
