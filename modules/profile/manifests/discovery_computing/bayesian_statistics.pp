# Provision for Bayesian statistics
#
# Install and configure R and install Discovery-specific essential R/Python
# packages for Markov chain Monte Carlo (MCMC) sampling when performing
# Bayesian inference.
#
# Due to the outdated version of R on the currently available Ubuntu version
# (Trusty), it is recommended to only apply this profile (and any profiles or
# roles that include it) to instances running on Debian (Jessie or newer).
#
# TODO: add PyStan (Python interface to Stan) and Edward (Python library for
#       probabilistic modeling, inference, and criticism) at some point. May
#       need to create a "pip" class for installing packages from PyPi. Also,
#       Edward is built on TensorFlow but TF would need to go into a separate
#       discovery_computing::deep_learning class along with Keras and others.
#
# filtertags: labs-project-discovery-stats
class profile::discovery_computing::bayesian_statistics {
    require profile::discovery_computing::base

    $python_packages = [
        'python-pymc', # Bayesian Stochastic Modelling in Python (http://pymc-devs.github.io/pymc/)
    ]
    require_package($python_packages)

    $r_packages = [
        'rstan',    # R Interface to Stan
        'rstanarm', # Bayesian Applied Regression Modeling via Stan
        'brms'      # Bayesian Regression Models using Stan
    ]
    r_lang::cran { $r_packages:
        require => [
            R_lang::Cran['Rcpp'],
            R_lang::Cran['RcppEigen'],
            R_lang::Cran['BH']
        ],
    }

}
