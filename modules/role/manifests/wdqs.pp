# = Class: role::wdqs
#
# This class sets up Wikidata Query Service
class role::wdqs  {
    include ::standard
    include ::profile::base::firewall
    include ::role::lvs::realserver
    include ::profile::wdqs

    system::role { 'wdqs':
        ensure      => 'present',
        description => 'Wikidata Query Service',
    }
}
