# = Class: role::wdqs::public
#
# This class sets up Wikidata Query Service for the public facing endpoint.
class role::wdqs::public {
    # Standard for all roles
    include profile::base::production
    include profile::firewall
    # Standard wdqs installation
    require profile::nginx
    require profile::query_service::wikidata
    require profile::query_service::categories
    require profile::query_service::monitor::wikidata_public
    # Production specific profiles
    include profile::lvs::realserver
    # Public endpoint specific profiles
    include profile::tlsproxy::envoy # TLS termination

    system::role { 'wdqs::public':
        ensure      => 'present',
        description => 'Wikidata Query Service - publicly available service',
    }
}
