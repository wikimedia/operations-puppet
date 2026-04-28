# SPDX-License-Identifier: Apache-2.0
# = Class: role::wdqs::internal_main
#
# This class sets up the Wikidata Query Service main graph
# for internal prod cluster use cases.
class role::wdqs::internal_main {
    # Standard for all roles
    include profile::base::production
    include profile::firewall
    # Standard wdqs installation
    require profile::nginx
    require profile::query_service::wikidata
    require profile::query_service::monitor::wikidata_internal_main
    # Production specific profiles
    include profile::lvs::realserver
    include profile::lvs::realserver::ipip

    # Internal-only profiles
    include profile::tlsproxy::envoy # TLS termination

    # temporarily add wdqs-categories role to internal-main hosts
    # until the service has migrated. See T375520 for details.
    require profile::query_service::categories
}

