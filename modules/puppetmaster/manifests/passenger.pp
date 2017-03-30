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
    $bind_address,
    $verify_client,
    $allow_from,
    $deny_from,
) {
    include ::apache::mod::passenger

    package { 'puppetmaster-passenger':
        ensure => present,
    }

    # jessie-specific instructions
    if os_version('debian >= jessie') {
        # Debian jessie needs the DH params file
        include ::sslcert::dhparam
    }

    # Set a unicode capable locale to avoid "SERVER: invalid byte sequence in
    # US-ASCII" errors when puppetmaster is started with LANG that doesn't
    # support non-ASCII encoding.
    # See <https://tickets.puppetlabs.com/browse/PUP-1386#comment-62325>
    apache::env { 'use-utf-locale':
        ensure => present,
        vars   => {
            'LANG' => 'en_US.UTF-8',
        },
    }

    apache::conf { 'passenger':
        content  => template('puppetmaster/passenger.conf.erb'),
        priority => 10,
    }

    apache::conf { 'puppetmaster_ports':
        content => template('puppetmaster/ports.conf.erb'),
    }

    # Unfortunately priority does not allows to use apache::site for this
    # Purging the package installed puppetmaster site
    file { '/etc/apache2/site-enabled/puppetmaster':
        ensure  => absent,
        require => Package['puppetmaster-passenger'],
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
        # We also make sure puppet master can not be manually started
        file { '/etc/default/puppetmaster':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///modules/puppetmaster/default',
            require => [
                Package['puppetmaster-passenger'],
                Package['puppetmaster-common']
            ],
        }
    }

    # Rotate apache logs is now managed via the apache::logrotate class
    file { '/etc/logrotate.d/passenger':
        ensure => absent,
    }
}
