# = Class: role::product_analytics::forecaster
#
# This class sets up R and Python packages for time series forecasting.
#
# Due to the outdated version of R on the currently available Ubuntu version
# (Trusty), it is recommended to only apply this role to instances running on
# Debian (Jessie or newer).
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
