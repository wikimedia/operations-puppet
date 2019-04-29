# = Class: role::discovery::dashboards
#
# This class sets up R/Shiny-based Discovery Dashboards
# for tracking Search, Wikipedia.org portal, Wikidata
# Query Service, and Maps usage metrics and other KPIs.
#
# filtertags: labs-project-search labs-project-shiny-r
class role::discovery::dashboards {
    # include ::profile::standard
    # include ::profile::base::firewall
    include ::profile::discovery_dashboards::production

    system::role { 'role::discovery::dashboards':
        ensure      => 'present',
        description => 'Discovery Dashboards (Production)',
    }

}
