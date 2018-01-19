# Provision Shiny Server and Discovery Dashboards
#
# Install and configure Shiny Server, install Discovery-specific R packages,
# and clone Discovery's dashboards.
#
# filtertags: labs-project-search labs-project-shiny-r
class profile::discovery_dashboards::base {
    require profile::shiny_server

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

    # 'polloi' contains common functions & data used by all the dashboards
    r_lang::git { 'polloi':
        url => 'https://gerrit.wikimedia.org/r/wikimedia/discovery/polloi',
    }

    # 'googleCharts' is used on the Wikipedia.org portal metrics dashboard
    r_lang::github { 'googleCharts':
        repo => 'jcheng5/googleCharts',
    }

    # Set up a portal to the various dashboards:
    file { '/srv/shiny-server/index.html':
        ensure => 'present',
        owner  => 'shiny',
        group  => 'staff',
        mode   => '0440',
        source => 'puppet:///modules/profile/discovery_dashboards/index.html',
    }

}
