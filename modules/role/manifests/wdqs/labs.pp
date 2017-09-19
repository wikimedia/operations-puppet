# = Class: role::wdqs::labs
#
# This class sets up Wikidata Query Service on Cloud VPS
#
# filtertags: labs-project-wikidata-query
class role::wdqs::labs () {
    require role::labs::lvm::srv

    include ::standard
    include ::base::firewall
    include ::profile::wdqs

    system::role { 'wdqs':
        ensure      => 'present',
        description => 'Wikidata Query Service',
    }
}