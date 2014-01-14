# Class: pmacct
#
# This installs and mangages pmacct configuraiton
# http://www.pmacct.net/
#
# Will initially be added to node 'netmon1001'

class pmacct {

    # Note: $pmacct::home does not work here...  ?
    $home  = '/srv/pmacct'

    # mysql
    $mysqlhost = '127.0.0.1'
    $mysqluser = 'pmacct'
    $mysqlpass = $passwords::pmacct::mysqlpass

    # Package (have a fresh one built by Faidon)
    # --enable-mysql --enable-64bit --enable-threads --enable-geoip
    # and added to our repo?
    package { 'pmacct':
        ensure => installed,
    }

    # User creation (not done by package)
    generic::systemuser { 'pmacct':
        name => 'pmacct',
        home => "${pmacct::home}",
        shell => '/bin/sh',
    }

    # Home directory
    file { "${pmacct::home}":
        ensure => 'directory',
        owner  => 'pmacct',
        group  => 'pmacct',
        mode   => '0750',
    }

    # Log directory
    file { "${pmacct::home}/logs":
        ensure  => 'directory',
        owner   => 'pmacct',
        group   => 'pmacct',
        mode    => '0750',
        require => File[ "${pmacct::home}" ],
    }

    # Config directory
    file { "${pmacct::home}/configs":
        ensure  => 'directory',
        owner   => 'pmacct',
        group   => 'pmacct',
        mode    => '0750',
        require => File[ "${pmacct::home}" ],
    }

    # Device list (nice to keep it in it's own world)
    require 'pmacct::devices'

    # Iterate over the device list to create new configs
    # FIXME: Review daniel's different method for iterating over a hash..
    create_resources('pmacct::makeconfig', $pmacct::devices::list)

    # Iterate over the device list to verify/check iptables redirects
    # FIXME: ferm (should probably happen in one iterate...


    # FIXME: make sure services are running (not start/stop scripts)
    # ...
}


