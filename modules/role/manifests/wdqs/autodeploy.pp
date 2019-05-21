# = Class: role::wdqs::autodeploy
#
# This class sets up Wikidata Query Service Automated Deployment
class role::wdqs::autodeploy {
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log
    require ::profile::wdqs::common
    require ::profile::wdqs::blazegraph
    require ::profile::wdqs::updater
    require ::profile::wdqs::gui

    system::role { 'wdqs::autodeploy':
        ensure      => 'present',
        description => 'Wikidata Query Service - automated deployment',
    }
}
