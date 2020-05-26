# = Class: role::wdqs::public
#
# This class sets up Wikidata Query Service for the public facing endpoint.
class role::wdqs::public {
    # Standard for all roles
    include ::profile::standard
    include ::profile::base::firewall
    # Standard wdqs installation
    require ::profile::query_service::common
    require ::profile::query_service::blazegraph
    require ::profile::query_service::categories
    require ::profile::query_service::updater
    require ::profile::query_service::gui
    # Production specific profiles
    include ::profile::lvs::realserver
    # Public endpoint specific profiles
    include ::profile::tlsproxy::envoy # TLS termination

    system::role { 'wdqs::public':
        ensure      => 'present',
        description => 'Wikidata Query Service - publicly available service',
    }
}
