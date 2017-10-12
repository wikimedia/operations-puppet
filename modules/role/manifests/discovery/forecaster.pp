# = Class: role::discovery::forecaster
#
# This class sets up R and Python packages for forecasting.
#
# Due to the outdated version of R on the currently available Ubuntu version
# (Trusty), it is recommended to only apply this role to instances running on
# Debian (Jessie or newer).
#
# filtertags: labs-project-discovery-stats
class role::discovery::forecaster {
    # include ::standard
    # include ::base::firewall
    include ::profile::discovery_computing::forecasting

    system::role { 'role::discovery::forecaster':
        ensure      => 'present',
        description => 'Forecasting for Discovery Analysts',
    }

}
