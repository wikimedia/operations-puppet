# Provision Shiny Server and WDCM Dashboards
#
# Install and configure Shiny Server, install WDCM-specific R packages,
# and clone WDCM's dashboards.
#
# filtertags: labs-project-wikidataconcepts labs-project-wmde-dashboards
class profile::wdcm_dashboards::base {
    include ::shiny_server

    $cran_packages = [
        #WDCM & TW dashboards need these
        'data.table',
        'dplyr',
        'DT',
        'ggplot2',
        'ggrepel',
        'ggvis',
        'htmltab',
        'httr',
        'igraph',
        'jsonlite',
        'leaflet',
        'maptpx',
        'networkD3',
        'parallelDist',
        'rbokeh',
        'RColorBrewer',
        'readr',
        'reshape2',
        'RMySQL',
        'Rtsne',
        'scales',
        'shiny',
        'shinycssloaders',
        'smacof',
        'snowfall',
        'stringr',
        'tidyr',
        'visNetwork',
        'wordcloud',
        'XML',
        #TW dashboards also need this
        'shinydashboard'
    ]
    r_lang::cran { $cran_packages:
        mirror => 'https://cran.cnr.berkeley.edu',
    }

    # Set up a portal to the various dashboards:
    file { '/srv/shiny-server/index.html':
        ensure => 'present',
        owner  => 'shiny',
        mode   => '0440',
        #TODO wdcm or wmde?
        #TODO actually make this file.....
        source => 'puppet:///modules/profile/wdcm_dashboards/index.html',
    }

}
