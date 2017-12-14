# = Class: role::wdqs
#
# This class sets up Wikidata Query Service
class role::wdqs  {
    include ::standard
    include ::base::firewall
    include ::role::lvs::realserver
    include ::profile::wdqs
    include ::profile::prometheus::wdqs_updater_exporter
    include ::profile::prometheus::blazegraph_exporter

    system::role { 'wdqs':
        ensure      => 'present',
        description => 'Wikidata Query Service',
    }
}
