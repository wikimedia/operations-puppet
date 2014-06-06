# Class: pmacct::install
#
# This installs and mangages pmacct configuration
# http://www.pmacct.net/
class pmacct::install {

    # Package
    # Must be built with these configure flags
    # --enable-mysql --enable-64bit --enable-threads --enable-geoip
    package { 'pmacct':
        ensure => installed,
    }

    # User creation (not done by package)
    user { 'pmacct':
        home       => '/var/lib/pmacct',
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
        require    => Package['pmacct'],
    }

    # Log directory
    file { '/var/log/pmacct':
        ensure  => 'directory',
        owner   => 'pmacct',
        group   => 'pmacct',
        mode    => '0750',
        require => Package['pmacct'],
    }

    # Config directory
    file { '/etc/pmacct':
        ensure  => 'directory',
        owner   => 'pmacct',
        group   => 'pmacct',
        mode    => '0750',
        require => Package['pmacct'],
    }

    # Pretag map file
    file { '/etc/pmacct/pretag.map':
        ensure  => present,
        owner   => 'pmacct',
        group   => 'pmacct',
        mode    => '0440',
        require => File['/etc/pmacct'],
    }

    # Populate pretag file
    file_line { 'HEADER':
        line    => '# WARNING: This file is maintained by puppet.',
        path    => '/etc/pmacct/pretag.map',
        require => File['/etc/pmacct/pretag.map'],
    }
}
