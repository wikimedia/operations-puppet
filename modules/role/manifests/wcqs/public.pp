# = Class: role::wcqs::public
#
# This class sets up Wikimedia Commons Query Service with the Structured
# Data on Commons dataset to service public queries from prod infra
class role::wcqs::public {
    # Standard for all roles
    include ::profile::standard
    include ::profile::base::firewall
    # Standard wcqs installation
    require ::profile::query_service::wcqs

    system::role { 'wcqs::public':
        ensure      => 'present',
        description => 'Wikimedia Commons Query Service - publicly available service'
    }
}
