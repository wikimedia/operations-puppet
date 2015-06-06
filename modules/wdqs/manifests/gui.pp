# == Class: wdqs::packages
#
# Provisions WDQS GUI
#
# == Parameters:
# - $package_dir:  Directory where the service is installed. 
# GUI files are expected to be under its gui/ directory.
# - $log_aggregator: Where to send the logs for the service.
#
class wdqs::gui(
    $package_dir,
    $log_aggregator,
) {
    ::nginx::site { 'wdqs':
        content => template('wdqs/nginx.erb'),
    }
}
