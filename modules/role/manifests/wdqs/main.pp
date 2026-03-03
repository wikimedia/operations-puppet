# SPDX-License-Identifier: Apache-2.0
# = Class: role::wdqs::main
#
# This class sets up Wikidata Query Service for the query-main public facing endpoint.
class role::wdqs::main {
    # Standard for all roles
    include profile::base::production
    include profile::firewall
    # Standard wdqs installation
    require profile::nginx
    require profile::query_service::wikidata
    require profile::query_service::monitor::wikidata_main
    # Production specific profiles
    include profile::lvs::realserver
    include profile::lvs::realserver::ipip
    # Public endpoint specific profiles
    include profile::tlsproxy::envoy # TLS termination

    # temporarily add wdqs-categories role to internal-main hosts
    # until the service has migrated. See T375520 for details.
    require profile::query_service::categories

}
