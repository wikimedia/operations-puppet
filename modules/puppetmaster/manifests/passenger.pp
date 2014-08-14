# Class: puppetmaster::passenger
#
# This class handles the Apache Passenger specific parts of a Puppetmaster
#
# Parameters:
#    - $bind_address:
#        The IP address Apache will bind to
#    - $verify_client:
#        Whether apache mod_ssl will verify the client (SSLVerifyClient option)
#    - $allow_from:
#        Adds an Allow from statement (order Allow,Deny), limiting access
#        to the passenger service.
#    - $deny_from:
#        Adds a Deny from statement (order Allow,Deny), limiting access
#        to the passenger service.
class puppetmaster::passenger(
    $bind_address  = '*',
    $verify_client = 'optional',
    $allow_from    = [],
    $deny_from     = []
) {
    include ::apache::mod::passenger

    apt::puppet { 'passenger':
        packages => 'puppetmaster-passenger',
        before   => Package['puppetmaster-passenger'],
    }

    package { 'puppetmaster-passenger':
        ensure => latest,
    }

    apache::site { 'puppetmaster.wikimedia.org':
        content => template('puppetmaster/puppetmaster.erb'),
    }

    apache::conf { 'puppetmaster_ports':
        content => template('puppetmaster/ports.conf.erb'),
    }

    # Since we are running puppet via passenger, we need to ensure
    # the puppetmaster service is stopped, since they use the same port
    # and will conflict when both started.
    if defined(Class['puppetmaster']) {
        service { 'puppetmaster':
            ensure => stopped,
            enable => false,
            before => Service['apache2'],
        }
    }

    # Rotate apache logs
    file { '/etc/logrotate.d/passenger':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/puppetmaster/logrotate-passenger',
    }

    # Installed by apache2.x-common and would override our settings
    file { '/etc/logrotate.d/apache2':
        ensure => absent,
    }
}
