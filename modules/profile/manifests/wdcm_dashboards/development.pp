# Provision Shiny Server and WDCM Dashboards
#
# Install and configure Shiny Server, install WDCM-specific R packages,
# and clone "master" branch of WDCM's dashboards so it has the latest
# versions (which may have unfinished features).
#
# filtertags: labs-project-wikidataconcepts labs-project-wmde-dashboards
class profile::wdcm_dashboards::development {
    require profile::wdcm_dashboards::base

    # Set up the clone of the front page
    git::clone { 'analytics/wmde/WDCM_ShinyServerFrontPage':
        ensure    => 'latest',
        owner     => 'shiny',
        mode      => '0440',
        directory => '/srv/shiny-server/wdcm/home',
        notify    => Service['shiny-server'],
        branch    => 'master',
    }

    # Set up clones of individual dashboard repos, triggering a restart
    # of the Shiny Server service if any of the clones are updated:
    git::clone { 'analytics/wmde/WDCM-GeoDashboard':
        ensure    => 'latest',
        owner     => 'shiny',
        directory => '/srv/shiny-server/wdcm/geo',
        notify    => Service['shiny-server'],
        branch    => 'master',
    }
    git::clone { 'analytics/wmde/WDCM-Overview-Dashboard':
        ensure    => 'latest',
        owner     => 'shiny',
        directory => '/srv/shiny-server/wdcm/overview',
        notify    => Service['shiny-server'],
        branch    => 'master',
    }
    git::clone { 'analytics/wmde/WDCM-Semantics-Dashboard':
        ensure    => 'latest',
        owner     => 'shiny',
        directory => '/srv/shiny-server/wdcm/semantics',
        notify    => Service['shiny-server'],
        branch    => 'master',
    }
    git::clone { 'analytics/wmde/WDCM-Structure-Dashboard':
        ensure    => 'latest',
        owner     => 'shiny',
        directory => '/srv/shiny-server/wdcm/structure',
        notify    => Service['shiny-server'],
        branch    => 'master',
    }
    git::clone { 'analytics/wmde/WDCM-Usage-Dashboard':
        ensure    => 'latest',
        owner     => 'shiny',
        directory => '/srv/shiny-server/wdcm/usage',
        notify    => Service['shiny-server'],
        branch    => 'master',
    }

}
