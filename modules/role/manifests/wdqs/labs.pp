# = Class: role::wdqs::labs
#
# This class defines a Wikidata Query Service endpoint inside
# Wikimedia Cloud Services.
#
class role::wdqs::labs () {
    # Standard for all roles
    include profile::base::production
    include profile::firewall
    # Standard wdqs installation
    require profile::nginx
    require profile::query_service::categories
    require profile::query_service::wikidata
    # Specific to instances in cloud services
    require role::labs::lvm::srv
}
