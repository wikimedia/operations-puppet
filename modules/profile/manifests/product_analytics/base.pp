# Provision for statistical computing and number crunching
#
# Install and configure R & Python and install Product Analytics-specific
# essential R/Python packages.
#
# filtertags: labs-project-discovery-stats
class profile::product_analytics::base {
    # `include ::r` would not install devtools, which would mean that we could
    # not install R packages from Git/GitHub
    class { 'r_lang':
        devtools => true,
    }

    $essentials = [
        'liblapack-dev',      # Library of linear algebra routines
        'libgsl0-dev',        # GNU Scientific Library
        'build-essential',    # for building stuff
        # Python libraries:
        'virtualenv',         # virtual environment creator
        'python-pip',
        'python3-pip',
        'python-setuptools',
        'python3-setuptools',
        'python-wheel',       # built-package format
        'python3-wheel',
        'python-dev',         # header files and a static library
        'python3-dev',
        'python-numpy',       # numerical library
        'python3-numpy',
        'python-scipy',       # scientific tools
        'python3-scipy',
        'python-pandas',      # data structures for "relational" or "labeled" data
        'python3-pandas',
        'python-requests',    # HTTP library
        'python3-requests',
        'python-h5py',        # Python interface to HDF5
        'python3-h5py',
        'cython',             # C-Extensions for Python
        'cython3'
    ]
    require_package($essentials)

    $cran_packages = [
        # Essentials
        'BH',         # Boost C++ Header Files
        'Rcpp',       # R and C++ Integration
        'R6',         # Classes with Reference Semantics
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
        'RcppNumerical', # 'Rcpp' Integration for Numerical Computing Libraries
        'reticulate',    # R interface to Python modules, classes, and functions
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
        timeout => 16000,
    }
    # The tidy modeling "verse" is a collection of package for modeling
    # and statistical analysis that share the underlying design philosophy,
    # grammar, and data structures of the tidyverse.
    r_lang::cran { 'tidymodels':
        require => R_lang::Cran['tidyverse'],
        timeout => 16000,
    }

    package { 'tensorflow':
        ensure   => 'installed',
        require  => [
            Package['python-dev'],
            Package['python-numpy'],
            Package['python-wheel']
        ],
        provider => 'pip',
    }
    r_lang::cran { 'tensorflow':
        require => [
            Package['tensorflow'],
            R_lang::Cran['reticulate']
        ],
    }

}
