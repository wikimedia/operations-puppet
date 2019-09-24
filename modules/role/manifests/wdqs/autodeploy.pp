# = Class: role::wdqs::autodeploy
#
# This class sets up Wikidata Query Service Automated Deployment
class role::wdqs::autodeploy {
    include ::profile::standard
    include ::profile::base::firewall
    require ::profile::query_service::common
    require ::profile::query_service::blazegraph
    require ::profile::query_service::updater
    require ::profile::query_service::gui

    system::role { 'wdqs::autodeploy':
        ensure      => 'present',
        description => 'Wikidata Query Service - automated deployment',
    }
}
