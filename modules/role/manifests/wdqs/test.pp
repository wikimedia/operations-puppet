# = Class: role::wdqs::test
#
# This class sets up Wikidata Query Service
class role::wdqs::test {
    include ::standard
    include ::profile::base::firewall
    include ::profile::wdqs

    system::role { 'wdqs::test':
        ensure      => 'present',
        description => 'Wikidata Query Service - test cluster',
    }
}
