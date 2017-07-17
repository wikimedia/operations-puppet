# == Class: wdqs::gui
#
# Provisions WDQS GUI
#
# == Parameters:
# - $package_dir:  Directory where the service is installed.
# GUI files are expected to be under its gui/ directory.
# - $log_aggregator: Where to send the logs for the service.
#
class wdqs::gui(
    $log_aggregator = undef,
    $package_dir = $::wdqs::package_dir,
    $port = 80,
    $additional_port = 8888,
    $bad_clients = undef,
) {
    file { '/etc/nginx/bad_clients.conf':
        content => template('wdqs/bad_clients.erb'),
    }

    ::nginx::site { 'wdqs':
        content => template('wdqs/nginx.erb'),
        require => File['/etc/nginx/bad_clients.conf']
    }

    # The directory for operator-controlled nginx flags
    file { '/var/lib/nginx/wdqs/':
        ensure  => directory,
        owner   => 'root',
        group   => 'wikidev',
        mode    => '0775',
        require => Nginx::Site['wdqs'],
    }
}
