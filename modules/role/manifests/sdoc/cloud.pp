# = Class: role::sdoc::cloud
#
# This class sets up Wikidata Query Service with the Structured
# Data on Commons dataset inside Wikimedia Cloud Services.
class role::sdoc::cloud {
    # Standard for all roles
    include ::profile::standard
    include ::profile::base::firewall
    # Standard sdoc installation
    require ::profile::query_service::sdoc
    # Cloud specific profiles
    require ::role::labs::lvm::srv

    system::role { 'sdoc::cloud':
        ensure      => 'present',
        description => 'Graph Query Service for SDoC in WMCS'
    }
}
