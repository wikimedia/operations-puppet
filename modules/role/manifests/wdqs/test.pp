# = Class: role::wdqs::test
#
# This class sets up Wikidata Query Service for testing purposes. Not
# exposed to public or private clients.
class role::wdqs::test {
    # Standard for all roles
    include profile::base::production
    include profile::firewall
    # Standard wdqs installation
    require profile::nginx
    require profile::query_service::wikidata
    # T350106 temporary firewall rules
    require profile::query_service::graph_split
    include profile::tlsproxy::envoy # TLS termination
}
