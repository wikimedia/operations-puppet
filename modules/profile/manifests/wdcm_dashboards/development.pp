# Provision Shiny Server and WDCM Dashboards
#
# Install and configure Shiny Server, install WDCM-specific R packages,
# and clone "master" branch of WDCM's dashboards so it has the latest
# versions (which may have unfinished features).
#
# filtertags: labs-project-wikidataconcepts
class profile::wdcm_dashboards::development {
    require profile::wdcm_dashboards::base

    # Set up clones of individual dashboard repos, triggering a restart
    # of the Shiny Server service if any of the clones are updated:
    # TODO clone correct repo
    git::clone { 'wikimedia/discovery/rainbow':
        ensure    => 'latest',
        directory => '/srv/shiny-server/metrics',
        notify    => Service['shiny-server'],
        branch    => 'master',
    }

}
