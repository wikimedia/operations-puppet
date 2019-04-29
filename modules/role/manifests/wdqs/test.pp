# = Class: role::wdqs::test
#
# This class sets up Wikidata Query Service
class role::wdqs::test {
    include ::profile::standard
    include ::profile::base::firewall
    require ::profile::wdqs::common
    require ::profile::wdqs::blazegraph
    require ::profile::wdqs::updater
    require ::profile::wdqs::gui

    system::role { 'wdqs::test':
        ensure      => 'present',
        description => 'Wikidata Query Service - test cluster',
    }
}
