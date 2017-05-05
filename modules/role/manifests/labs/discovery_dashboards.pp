# Provision Shiny Server and Discovery Dashboards
#
# Install and configure Shiny Server, install Discovery-specific R packages,
# and clone Discovery's dashboards.
#
# filtertags: labs-project-search labs-project-shiny-r
class role::labs::discovery_dashboards {
    include shiny_server

    $cran_packages = [
        # Needed by Search metrics dashboard:
        'sparkline',
        'toOrdinal',
        # Needed by Wikipedia.org portal metrics dashboard:
        'highcharter',
        'countrycode'
    ]
    shiny_server::cran_pkg { $cran_packages:
        mirror => 'https://cran.cnr.berkeley.edu',
    }

    # 'polloi' contains common functions & data used by all the dashboards
    shiny_server::git_pkg { 'polloi':
        url => 'https://gerrit.wikimedia.org/r/wikimedia/discovery/polloi',
    }

    # 'googleCharts' is used on the Wikipedia.org portal metrics dashboard
    shiny_server::github_pkg { 'googleCharts':
        repo => 'jcheng5/googleCharts',
    }

    # Set up a portal to the various dashboards:
    file { '/srv/shiny-server/index.html':
        ensure => 'present',
        owner  => 'shiny',
        group  => 'staff',
        mode   => '0440',
        source => 'puppet:///modules/role/labs/discovery_dashboards/index.html',
    }

    # Set up clones of individual dashboard repos, triggering a restart
    # of the Shiny Server service if any of the clones are updated:
    git::clone { 'wikimedia/discovery/rainbow':
        ensure    => 'latest',
        directory => '/srv/shiny-server/metrics',
        notify    => Service['shiny-server']
    }
    git::clone { 'wikimedia/discovery/twilightsparql':
        ensure    => 'latest',
        directory => '/srv/shiny-server/wdqs',
        notify    => Service['shiny-server']
    }
    git::clone { 'wikimedia/discovery/prince':
        ensure    => 'latest',
        directory => '/srv/shiny-server/portal',
        notify    => Service['shiny-server']
    }
    git::clone { 'wikimedia/discovery/wetzel':
        ensure    => 'latest',
        directory => '/srv/shiny-server/maps',
        notify    => Service['shiny-server']
    }
    git::clone { 'wikimedia/discovery/wonderbolt':
        ensure    => 'latest',
        directory => '/srv/shiny-server/external',
        notify    => Service['shiny-server']
    }

}

