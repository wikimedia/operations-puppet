# = Class: role::wdqs::internal
#
# This class sets up Wikidata Query Service for internal prod cluster use
# cases.
class role::wdqs::internal {
    # Standard for all roles
    include profile::base::production
    include profile::firewall
    # Standard wdqs installation
    require profile::nginx
    require profile::query_service::categories
    require profile::query_service::wikidata
    require profile::query_service::monitor::wikidata_internal
    # Production specific profiles
    include profile::lvs::realserver

    # wdqs-internal specific profiles
    include profile::tlsproxy::envoy # TLS termination

    system::role { 'wdqs::internal':
        ensure      => 'present',
        description => 'Wikidata Query Service - internally available service',
    }
}
