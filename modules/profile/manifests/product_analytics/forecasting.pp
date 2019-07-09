# Provision for forecasting
#
# Install and configure R and install Product Analytics-specific essential
# R/Python2 packages for training time series models and generating forecasts.
#
# filtertags: labs-project-discovery-stats
class profile::product_analytics::forecasting {
    require profile::product_analytics::probabilistic

    $r_packages = [
        'forecast', # Forecasting Functions for Time Series and Linear Models
        'prophet',  # Automatic Forecasting Procedure
        'bsts'      # Bayesian Structural Time Series
    ]
    r_lang::cran { $r_packages:
        require => R_lang::Cran['rstan'],
        timeout => 12000,
    }

    package { 'pystan':
        ensure   => 'installed',
        require  => [
            Package['python-dev'],
            Package['python-numpy'],
            Package['python-cython']
        ],
        provider => 'pip',
    }
    package { 'fbprophet':
        ensure   => 'installed',
        require  => [
            Package['pystan']
        ],
        provider => 'pip',
    }

}
