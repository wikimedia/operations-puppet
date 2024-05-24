# = Class: role::wcqs::public
#
# This class sets up Wikimedia Commons Query Service with the Structured
# Data on Commons dataset to service public queries from prod infra
class role::wcqs::public {
    # Standard for all roles
    include profile::base::production
    include profile::firewall
    # Standard wcqs installation
    require profile::query_service::wcqs
    # Public endpoint specific profiles
    include profile::tlsproxy::envoy # TLS termination
    # Production specific profiles
    include profile::lvs::realserver
}
