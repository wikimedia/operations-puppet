# Provision for statistical computing and number crunching
#
# Install and configure R and install Discovery-specific essential R/Python
# packages for doing computationally-heavy statistics and machine learning.
#
# Due to the outdated version of R on the currently available Ubuntu version
# (Trusty), it is recommended to only apply this profile (and any profiles or
# roles that include it) to instances running on Debian (Jessie or newer).
#
# filtertags: labs-project-discovery-stats
class profile::discovery_computing::base {
    # `include ::r` would not install devtools, which would mean that we could
    # not install R packages from Git/GitHub
    class { 'r_lang':
        devtools => true,
    }

    $essentials = [
        'build-essential',    # for building stuff
        'virtualenv',         # Python virtual environment creator
        'python3-pip',        # for installing py libs
        'python3-setuptools', # also for installing py libs
        'liblapack-dev',      # Library of linear algebra routines
        'libgsl0-dev',        # GNU Scientific Library
        'python3-dev',        # header files and a static library for Python
        'python3-numpy',      # numerical library for Python
        'python3-scipy'       # scientific tools for Python
    ]
    require_package($essentials)

    $cran_packages = [
        # Essentials
        'BH',         # Boost C++ Header Files
        'Rcpp',       # R and C++ Integration
        # Data Manipulation
        'data.table', # fast data frames
        'glue',       # better than paste() for combining strings
        # Miscellaneous
        'optparse'    # needed for /etc/update-pkg.R
    ]
    r_lang::cran { $cran_packages: }

    $rcpp_integrations = [
        'RcppArmadillo', # 'Rcpp' Integration for the 'Armadillo' Templated Linear Algebra Library
        'RcppEigen',     # 'Rcpp' Integration for the 'Eigen' Templated Linear Algebra Library
        'RcppGSL',       # 'Rcpp' Integration for 'GNU GSL' Vectors and Matrices
        'RcppNumerical'  # 'Rcpp' Integration for Numerical Computing Libraries
    ]
    r_lang::cran { $rcpp_integrations:
        require => [
            Package['libgsl0-dev'],
            R_lang::Cran['Rcpp']
        ],
    }

    # tidyverse includes packages such as dplyr, tidyr, magrittr, readr,
    # ggplot2, broom, purrr, rvest, forcats, lubridate, and jsonlite
    # It's a lot of packages so we *really* need to extend the timeout.
    r_lang::cran { 'tidyverse':
        require => R_lang::Cran['Rcpp'],
        timeout => 12000,
    }

}
