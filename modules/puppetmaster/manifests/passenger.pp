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
                                $bind_address='*',
                                $verify_client='optional',
                                $allow_from=[],
                                $deny_from=[]
                            ) {
    package { [
                'puppetmaster-passenger',
                'libapache2-mod-passenger',
              ]:
        ensure => latest;
    }

    file {
        '/etc/apache2/sites-available/puppetmaster':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('puppetmaster/puppetmaster.erb');
        '/etc/apache2/ports.conf':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('puppetmaster/ports.conf.erb');
    }

    apache_module { 'passenger':
        name    => 'passenger',
        require => Package['libapache2-mod-passenger'];
    }
    apache_site { 'puppetmaster':
        name    => 'puppetmaster',
        require => Apache_module['passenger'];
    }

    # Since we are running puppet via passenger, we need to ensure
    # the puppetmaster service is stopped, since they use the same port
    # and will conflict when both started.
    if defined(Class['puppetmaster']) {
        service { 'puppetmaster':
            ensure => stopped,
            enable => false,
        }
    }

    # rotate apache logs
    file { '/etc/logrotate.d/passenger':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0664',
        source => 'puppet:///modules/puppetmaster/logrotate-passenger',
    }
    # installed by apache2.x-common and would override our settings
    file { '/etc/logrotate.d/apache2':
        ensure => absent,
    }
}
