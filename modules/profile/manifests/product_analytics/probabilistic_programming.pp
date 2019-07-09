# Provision for probabilistic programming
#
# Install and configure R and install Product Analytics-specific essential
# R/Python packages for statistical inference and modeling with probabilistic
# programming and Bayesian methods.
#
# filtertags: labs-project-discovery-stats
class profile::product_analytics::probabilistic_programming {
    require profile::product_analytics::base

    $r_packages = [
        'rstan',     # R Interface to Stan
        'rstanarm',  # Bayesian Applied Regression Modeling via Stan
        'brms',      # Bayesian Regression Models using Stan
        'tidybayes', # Tidy Data and 'Geoms' for Bayesian Models
    ]
    r_lang::cran { $r_packages:
        require => [
            R_lang::Cran['Rcpp'],
            R_lang::Cran['RcppEigen'],
            R_lang::Cran['BH'],
            R_lang::Cran['tidyverse']
        ],
        timeout => 9000,
    }
    r_lang::cran { 'greta':
        require => [
            R_lang::Cran['tensorflow'],
            R_lang::Cran['tidybayes']
        ]
    }

    $python_libraries = [
        'pymc3',                  # Bayesian statistical modeling & probabilistic ML
        'pystan',                 # Python interface to Stan
        'tensorflow-probability', # Probabilistic reasoning with TensorFlow
        'edward'                  # note: Edward2 is built into TF Probability
    ]
    package { $python_libraries:
        ensure   => 'installed',
        require  => [
            Package['python-dev'],
            Package['python-numpy'],
            Package['python-wheel'],
            Package['python-h5py'],
            Package['python-cython'],
            Package['tensorflow']
        ],
        provider => 'pip',
    }

}
