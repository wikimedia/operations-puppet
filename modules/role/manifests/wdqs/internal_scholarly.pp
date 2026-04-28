# SPDX-License-Identifier: Apache-2.0
# = Class: role::wdqs::internal_scholarly
#
# This class sets up the Wikidata Query Service scholarly graph
# for internal prod cluster use cases.
class role::wdqs::internal_scholarly {
    # Standard for all roles
    include profile::base::production
    include profile::firewall
    # Standard wdqs installation
    require profile::nginx
    require profile::query_service::wikidata
    require profile::query_service::monitor::wikidata_internal_scholarly
    # Production specific profiles
    include profile::lvs::realserver
    include profile::lvs::realserver::ipip

    # Internal-only profiles
    include profile::tlsproxy::envoy # TLS termination
}
