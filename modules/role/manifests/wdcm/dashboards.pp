# = Class: role::wdcm::dashboards
#
# This class sets up R/Shiny-based WDCM Dashboards
#
# filtertags: labs-project-wikidataconcepts
class role::wdcm::dashboards {
    # include ::standard
    # include ::base::firewall
    include ::profile::wdcm_dashboards::production

    system::role { 'role::wdcm::dashboards':
        ensure      => 'present',
        description => 'WDCM Dashboards (Production)',
    }

}
