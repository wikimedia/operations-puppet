# = Class: role::wdqs
#
# This class sets up Wikidata Query Service
class role::wdqs {
    include ::profile::standard
    include ::profile::lvs::realserver
    include ::profile::base::firewall
    require ::profile::query_service::common
    require ::profile::query_service::blazegraph
    require ::profile::query_service::updater
    require ::profile::query_service::gui
    include ::profile::tlsproxy::envoy # TLS termination

    system::role { 'wdqs':
        ensure      => 'present',
        description => 'Wikidata Query Service - publicly available service',
    }
}
