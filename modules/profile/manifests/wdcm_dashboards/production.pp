# Provision Shiny Server and WDCM Dashboards
#
# Install and configure Shiny Server, install WDCM-specific R packages,
# and clone release-ready versions of WDCM's dashboards.
#
# filtertags: labs-project-wikidataconcepts labs-project-wmde-dashboards
class profile::wdcm_dashboards::production {
    require profile::wdcm_dashboards::base

    # Set up the clone of the front page
    git::clone { 'analytics/wmde/WDCM_ShinyServerFrontPage':
        ensure    => 'present',
        owner     => 'shiny',
        mode      => '0440',
        directory => '/srv/shiny-server/wdcm/home',
        notify    => Service['shiny-server'],
        branch    => 'master',
    }

    # Set up clones of individual dashboard repos, triggering a restart
    # of the Shiny Server service if any of the clones are updated:
    git::clone { 'analytics/wmde/WDCM-GeoDashboard':
        ensure    => 'present',
        owner     => 'shiny',
        directory => '/srv/shiny-server/wdcm/geo',
        notify    => Service['shiny-server'],
        branch    => 'master',
    }
    git::clone { 'analytics/wmde/WDCM-Overview-Dashboard':
        ensure    => 'present',
        owner     => 'shiny',
        directory => '/srv/shiny-server/wdcm/overview',
        notify    => Service['shiny-server'],
        branch    => 'master',
    }
    git::clone { 'analytics/wmde/WDCM-Semantics-Dashboard':
        ensure    => 'present',
        owner     => 'shiny',
        directory => '/srv/shiny-server/wdcm/semantics',
        notify    => Service['shiny-server'],
        branch    => 'master',
    }
    git::clone { 'analytics/wmde/WDCM-Structure-Dashboard':
        ensure    => 'present',
        owner     => 'shiny',
        directory => '/srv/shiny-server/wdcm/structure',
        notify    => Service['shiny-server'],
        branch    => 'master',
    }
    git::clone { 'analytics/wmde/WDCM-Usage-Dashboard':
        ensure    => 'present',
        owner     => 'shiny',
        directory => '/srv/shiny-server/wdcm/usage',
        notify    => Service['shiny-server'],
        branch    => 'master',
    }

}
