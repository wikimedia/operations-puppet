# Class: puppetmaster::passenger
#
# This class handles the Apache Passenger specific parts of a Puppetmaster
#
# Parameters:
#    - $bind_address:
#        The IP address Apache will bind to
#    - $verify_client:
#        Whether apache mod_ssl will verify the client (SSLVerifyClient option)
class puppetmaster::passenger(
    Variant[Stdlib::IP::Address, Enum['*']] $bind_address,
    Httpd::SSLVerifyClient $verify_client,
){

    include sslcert::dhparam

    # Set a unicode capable locale to avoid "SERVER: invalid byte sequence in
    # US-ASCII" errors when puppetmaster is started with LANG that doesn't
    # support non-ASCII encoding.
    # See <https://tickets.puppetlabs.com/browse/PUP-1386#comment-62325>
    httpd::conf { 'use-utf-locale':
        ensure    => present,
        conf_type => 'env',
        content   => "export LANG=\"en_US.UTF-8\"\n",
    }

    httpd::conf { 'passenger':
        content  => template('puppetmaster/passenger.conf.erb'),
        priority => 10,
    }

    httpd::conf { 'puppetmaster_ports':
        content => template('puppetmaster/ports.conf.erb'),
    }

    # Place an empty puppet-master.conf file to prevent creation of this file
    # at package install time. Apache breaks if that happens. T179102
    file { '/etc/apache2/sites-available/puppet-master.conf':
        ensure  => present,
        content => '# This file intentionally left blank by puppet - T179102'
    }
    file { '/etc/apache2/sites-enabled/puppet-master.conf':
        ensure  => link,
        target  => '/etc/apache2/sites-available/puppet-master.conf',
        require => File['/etc/apache2/sites-available/puppet-master.conf'],
    }

    package { 'puppet-master-passenger':
        ensure => present,
    }

    # Since we are running puppet via passenger, we need to ensure
    # the puppetmaster service is stopped, since they use the same port
    # and will conflict when both started.
    if defined(Class['puppetmaster']) {
        service { 'puppetmaster':
            ensure => stopped,
            enable => false,
            before => Class['::httpd'],
        }
        # We also make sure puppet master can not be manually started
        file { '/etc/default/puppetmaster':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///modules/puppetmaster/default',
            require => [
                Package['puppet-master-passenger']
            ],
        }
    }
}
