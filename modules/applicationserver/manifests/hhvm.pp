# == Class: applicationserver::hhvm
#
# Configures the HipHop Virtual Machine for PHP, a fast PHP interpreter
# that is mostly compatible with the Zend interpreter. This module is a
# work-in-progress. It is designed to help test HHVM in Labs.
#
class applicationserver::hhvm {

    if $::realm != 'labs' {
        # The HHVM packages that are currently available do not meet the
        # standards of our production environment, so their use is currently
        # restricted to Labs.
        fail('applicationserver::hhvm may only be deployed to Labs.')
    }

    package { [ 'hhvm-fastcgi', 'libapache2-mod-fastcgi' ]:
        ensure => present,
    }

    exec {
        '/usr/sbin/a2enmod fastcgi':
            unless  => 'apache2ctl -M | grep -q fastcgi',
            require => Package['libapache2-mod-fastcgi'],
            before  => Service['hhvm'];
        '/usr/sbin/a2enmod actions':
            unless  => 'apache2ctl -M | grep -q actions',
            before  => Service['hhvm'];
        '/usr/sbin/a2enmod alias':
            unless  => 'apache2ctl -M | grep -q alias',
            before  => Service['hhvm'];
    }

    file { '/etc/hhvm/server.hdf':
        ensure  => file,
        source  => 'puppet:///modules/applicationserver/hhvm/server.hdf',
        require => Package['hhvm-fastcgi'],
        notify  => Service['hhvm'],
    }

    service { 'hhvm':
        ensure   => running,
        provider => debian,
        enable   => true,
        require  => File['/etc/hhvm/server.hdf'],
    }
}
