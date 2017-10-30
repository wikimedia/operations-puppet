# Provision Shiny Server and WDCM Dashboards
#
# Install and configure Shiny Server, install WDCM-specific R packages,
# and clone release-ready versions of WDCM's dashboards.
#
# filtertags: labs-project-wikidataconcepts
class profile::wdcm_dashboards::production {
    require profile::wdcm_dashboards::base

    # Set up clones of individual dashboard repos, triggering a restart
    # of the Shiny Server service if any of the clones are updated:
    # TODO currently we only have a master branch but we will have a master & production branch
    # TODO switch from present to latest and master to production
    # TODO clone correct repo
    git::clone { 'wikimedia/discovery/rainbow':
        ensure    => 'present',
        directory => '/srv/shiny-server/metrics',
        notify    => Service['shiny-server'],
        branch    => 'master',
    }

}
