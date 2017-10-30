# = Class: role::wdcm::dashboards
#
# This class sets up R/Shiny-based WDCM Dashboards
#
# filtertags: labs-project-wikidataconcepts
class role::wdcm::beta_dashboards {
    include ::profile::wdcm_dashboards::development

    system::role { 'role::wdcm::beta_dashboards':
        ensure      => 'present',
        description => 'WDCM Dashboards (Beta)',
    }

}
