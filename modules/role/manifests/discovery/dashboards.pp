# = Class: role::discovery::dashboards
#
# This class sets up R/Shiny-based Discovery Dashboards
# for tracking Search, Wikipedia.org portal, Wikidata
# Query Service, and Maps usage metrics and other KPIs.
#
class role::discovery::dashboards {
    include ::standard
    include ::base::firewall
    include ::profile::discovery_dashboards

    system::role { 'role::discovery::dashboards':
        ensure      => 'present',
        description => 'Discovery Dashboards',
    }

}
