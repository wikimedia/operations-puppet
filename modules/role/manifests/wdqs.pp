# = Class: role::wdqs
#
# This class sets up Wikidata Query Service
#
# filtertags: labs-project-wikidata-query
class role::wdqs  {
    include ::standard
    include ::base::firewall
    include ::role::lvs::realserver
    include ::profile::wdqs

    system::role { 'wdqs':
        ensure      => 'present',
        description => 'Wikidata Query Service',
    }
}
