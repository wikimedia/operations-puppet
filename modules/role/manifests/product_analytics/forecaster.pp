# = Class: role::product_analytics::forecaster
#
# This class sets up R and Python packages for time series forecasting.
#
# filtertags: labs-project-discovery-stats
class role::product_analytics::forecaster {
    # include ::profile::standard
    # include ::profile::base::firewall
    include ::profile::product_analytics::forecasting

    system::role { 'role::product_analytics::forecaster':
        ensure      => 'present',
        description => 'VM configured for time series forecasting',
    }

}
