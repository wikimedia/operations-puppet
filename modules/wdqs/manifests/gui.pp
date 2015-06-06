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
    require_package('nginx')

    file { '/etc/nginx/sites-enabled/default':
        content => template('wdqs/nginx.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['nginx'],
        notify  => Service['nginx'],
    }

    service { 'nginx':
        enable => true,
        require => File['/etc/nginx/sites-enabled/default'],
    }
}
