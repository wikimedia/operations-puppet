# = Class: role::product_analytics::forecaster
#
# This class sets up R and Python packages for time series forecasting.
#
class role::product_analytics::forecaster {
    # include ::profile::base::production
    # include ::profile::base::firewall
    include ::profile::product_analytics::forecasting

    system::role { 'role::product_analytics::forecaster':
        ensure      => 'present',
        description => 'VM configured for time series forecasting',
    }

}
