# Provision for forecasting
#
# Install and configure R and install Discovery-specific essential R/Python
# packages for training time series models and generating forecasts.
#
# Due to the outdated version of R on the currently available Ubuntu version
# (Trusty), it is recommended to only apply this profile (and any profiles or
# roles that include it) to instances running on Debian (Jessie or newer).
#
# filtertags: labs-project-discovery-stats
class profile::discovery_computing::forecasting {
    require profile::discovery_computing::bayesian_statistics

    $r_packages = [
        'forecast', # Forecasting Functions for Time Series and Linear Models
        'prophet',  # Automatic Forecasting Procedure
        'bsts'      # Bayesian Structural Time Series
    ]
    r_lang::cran { $r_packages:
        require => R_lang::Cran['rstan'],
        timeout => 9000,
    }

}
