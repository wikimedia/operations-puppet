# = Class: role::wcqs::cloud
#
# This class sets up Wikimedia Commons Query Service with the Structured
# Data on Commons dataset inside Wikimedia Cloud Services.
class role::wcqs::cloud {
    # Standard for all roles
    include profile::base::production
    include profile::firewall
    # Standard wcqs installation
    require profile::query_service::wcqs
    # Cloud specific profiles
    require role::labs::lvm::srv
}
