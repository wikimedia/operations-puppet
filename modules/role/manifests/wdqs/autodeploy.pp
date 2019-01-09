# = Class: role::wdqs::autodeploy
#
# This class sets up Wikidata Query Service Automated Deployment
class role::wdqs::autodeploy {
    include ::standard
    include ::profile::base::firewall
    require ::profile::wdqs::common
    require ::profile::wdqs::blazegraph
    require ::profile::wdqs::updater
    require ::profile::wdqs::gui

    system::role { 'wdqs::autodeploy':
        ensure      => 'present',
        description => 'Wikidata Query Service - automated deployment',
    }
}