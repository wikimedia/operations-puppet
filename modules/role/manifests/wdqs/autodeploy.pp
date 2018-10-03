# = Class: role::wdqs::autodeploy
#
# This class sets up Wikidata Query Service Automated Deployment
class role::wdqs::autodeploy {
    include ::standard
    include ::profile::base::firewall
    include ::profile::wdqs
    include ::profile::wdqs::autodeploy

    system::role { 'wdqs::autodeploy':
        ensure      => 'present',
        description => 'Wikidata Query Service - automated deployment',
    }
}