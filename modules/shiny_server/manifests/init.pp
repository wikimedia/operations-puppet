# = Class: shiny_sever
#
# Shiny Server enables users to host and manage Shiny applications on the
# Internet. Shiny is an R package that uses a reactive programming model
# to simplify the development of R-powered web applications. Shiny Server
# can manage R processes running various Shiny applications over different
# URLs and ports.
#
# This module sets up a Shiny Server service running on port 3838 and installs
# several R packages that are necessary for Shiny applications, including some
# that have been shown in practice to be useful.
#
# **Note**: that the CRAN mirror below is configured to use the UC Berkeley
# mirror of CRAN (https://cran.cnr.berkeley.edu/) as it is a trusted repository
# that also supports HTTPS. The default is 'https://cloud.r-project.org', which
# provides automatic redirection to servers worldwide (sponsored by RStudio).
# For a list of CRAN mirrors, see https://cran.r-project.org/mirrors.html
#
class shiny_server {

    $essentials = [
        'gfortran', 'g++-4.8', 'gfortran-4.8',
        'libssl-dev', 'libcurl4-openssl-dev', 'libxml2-dev', 'libssh2-1-dev',
        'libcairo2-dev', 'git-core', 'gdebi', 'pandoc',
        'r-base', 'r-base-dev', 'r-recommended'
    ]
    require_package($essentials)

    file { '/usr/local/lib/R/site-library':
        ensure => 'directory',
        owner  => 'root',
        group  => 'staff',
        mode   => '0770',
    }

    # R script for updating any particular installed R package:
    file { '/usr/local/bin/update-library.R':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0770',
        source => 'puppet:///modules/shiny_server/update-library.R'
    }

    # Install R packages from CRAN, Gerrit, and GitHub:
    $cran_mirror = 'https://cran.cnr.berkeley.edu'
    shiny_server::cran_pkg { 'curl':
        require => Package['libcurl4-openssl-dev'],
        mirror  => $cran_mirror,
    }
    shiny_server::cran_pkg { 'xml2':
        require => Package['libxml2-dev'],
        mirror  => $cran_mirror,
    }
    shiny_server::cran_pkg { 'devtools':
        require => [
            Package['git-core'],
            Shiny_server::Cran_pkg['curl']
        ],
        mirror  => $cran_mirror,
    }
    shiny_server::cran_pkg { 'rmarkdown':
        require => Package['pandoc'],
        mirror  => $cran_mirror,
    }
    # tidyverse includes packages such as dplyr, tidyr, magrittr, readr,
    # ggplot2, broom, purrr, rvest, forcats, lubridate, and jsonlite
    shiny_server::cran_pkg { 'tidyverse':
        timeout => 2700,
        mirror  => $cran_mirror
    }
    $cran_packages = [
        # Shiny Dashboarding
        'shiny', 'shinyjs', 'shinyWidgets', # shiny essentials
        'shinydashboard', 'flexdashboard',  # dashboarding
        'shinythemes',                      # bootstrap themes
        'shinyLP',                          # landing home pages for shiny apps
        # Data Manipulation
        'data.table',                       # fast data frames
        'plyr', 'reshape2',                 # pre-tidyr/dplyr wrangling pkgs
        'zoo', 'xts',                       # for working with time series data
        # Data Visualization
        'dygraphs',                         # time series plots
        'DT',                               # data tables
        # Misc.
        'knitr', 'markdown',
        'optparse'                          # needed for /etc/update-pkg.R
    ]
    shiny_server::cran_pkg { $cran_packages: mirror => $cran_mirror }

    # Set up files, directories, and users required for RStudio's Shiny Server:
    user { 'shiny':
        ensure     => 'present',
        managehome => true,
        groups     => 'staff',
    }
    file { '/home/shiny/downloads':
        ensure => 'directory',
        owner  => 'shiny',
        group  => 'staff',
        mode   => '0740',
    }

    file { '/srv/shiny-server':
        ensure => 'directory',
        owner  => 'shiny',
        group  => 'root',
        mode   => '2670',
    }

    file { '/etc/shiny-server':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '2770',
    }

    file { '/etc/shiny-server/shiny-server.conf':
        ensure => 'present',
        source => 'puppet:///modules/shiny_server/shiny-server.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0660',
    }

    # Assuming shiny-server-1.5.3.838-amd64.deb exists in the WMF apt repo...
    require_package('shiny-server')

    service { 'shiny-server':
        ensure => 'running',
        enable => true,
    }

}
