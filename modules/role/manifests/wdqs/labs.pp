# = Class: role::wdqs::labs
#
# This class defines a Wikidata Query Service endpoint inside
# Wikimedia Cloud Services.
#
# filtertags: labs-project-wikidata-query
class role::wdqs::labs () {
    # Standard for all roles
    include profile::standard
    include profile::base::firewall
    # Standard wdqs installation
    require profile::nginx
    require profile::query_service::categories
    require profile::query_service::wikidata
    # Specific to instances in cloud services
    require role::labs::lvm::srv

    system::role { 'wdqs::labs':
        ensure      => 'present',
        description => 'Wikidata Query Service',
    }
}
