# Provision Shiny Server and Discovery Dashboards
#
# Install and configure Shiny Server, install Discovery-specific R packages,
# and clone "develop" branch of Discovery's dashboards so it has the latest
# versions (which may have unfinished features).
#
# filtertags: labs-project-search labs-project-shiny-r
class profile::discovery_dashboards::development {
    require profile::discovery_dashboards::base

    # Set up clones of individual dashboard repos, triggering a restart
    # of the Shiny Server service if any of the clones are updated:
    git::clone { 'wikimedia/discovery/rainbow':
        ensure    => 'latest',
        directory => '/srv/shiny-server/metrics',
        notify    => Service['shiny-server'],
        branch    => 'develop',
    }
    git::clone { 'wikimedia/discovery/twilightsparql':
        ensure    => 'latest',
        directory => '/srv/shiny-server/wdqs',
        notify    => Service['shiny-server'],
        branch    => 'develop',
    }
    git::clone { 'wikimedia/discovery/prince':
        ensure    => 'absent',
        directory => '/srv/shiny-server/portal',
        branch    => 'develop',
    }
    git::clone { 'wikimedia/discovery/wetzel':
        ensure    => 'latest',
        directory => '/srv/shiny-server/maps',
        notify    => Service['shiny-server'],
        branch    => 'develop',
    }
    git::clone { 'wikimedia/discovery/wonderbolt':
        ensure    => 'latest',
        directory => '/srv/shiny-server/external',
        notify    => Service['shiny-server'],
        branch    => 'develop',
    }

}
