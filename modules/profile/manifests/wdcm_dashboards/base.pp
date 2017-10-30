# Provision Shiny Server and WDCM Dashboards
#
# Install and configure Shiny Server, install WDCM-specific R packages,
# and clone WDCM's dashboards.
#
# filtertags: labs-project-wikidataconcepts
class profile::wdcm_dashboards::base {
    include ::shiny_server

    #TODO update
    $cran_packages = [
        # Needed by Search metrics dashboard:
        'sparkline',
        'toOrdinal',
        # Needed by Wikipedia.org portal metrics dashboard:
        'highcharter',
        'countrycode'
    ]
    r_lang::cran { $cran_packages:
        mirror => 'https://cran.cnr.berkeley.edu',
    }

    #TODO is this needed?
    # 'polloi' contains common functions & data used by all the dashboards
    r_lang::git { 'polloi':
        url => 'https://gerrit.wikimedia.org/r/wikimedia/discovery/polloi',
    }

    #TODO is this needed?
    # 'googleCharts' is used on the Wikipedia.org portal metrics dashboard
    r_lang::github { 'googleCharts':
        repo => 'jcheng5/googleCharts',
    }

    #TODO setup the landing page somewhere
    #https://github.com/wikimedia/analytics-wmde-WDCM/tree/master/WDCM_ShinyServerFrontPage
    # Set up a portal to the various dashboards:
    # file { '/srv/shiny-server/index.html':
    #     ensure => 'present',
    #     owner  => 'shiny',
    #     # TODO udpate group? wmde? wmde-analytics?
    #     group  => 'staff',
    #     mode   => '0440',
    #     #TODO udpate the files for the portal!
    #     source => 'puppet:///modules/profile/discovery_dashboards/index.html',
    # }

}
