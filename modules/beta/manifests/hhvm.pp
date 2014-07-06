# == Class: beta::hhvm
#
# Configures the HipHop Virtual Machine for PHP, a fast PHP interpreter
# that is mostly compatible with the Zend interpreter. This module is a
# work-in-progress. It is designed to help test HHVM in Labs.
#
class beta::hhvm {
    if $::realm != 'labs' {
        # The HHVM packages that are currently available do not meet the
        # standards of our production environment, so their use is currently
        # restricted to Labs.
        fail('beta::hhvm may only be deployed to Labs.')
    }

    class { '::hhvm':
        require => Class['::apache::mod::fastcgi'],
    }

    include ::apache::mod::rewrite
    include ::apache::mod::actions
    include ::apache::mod::alias
    include ::apache::mod::fastcgi

    file { '/var/run/hhvm':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
    }

    # FIXME: This should be a parametrized template.
    file { '/etc/hhvm/server.hdf':
        source  => 'puppet:///modules/beta/hhvm/server.hdf',
        require => [ Package['hhvm'], File['/var/run/hhvm'] ],
        notify  => Service['hhvm'],
    }

    file { [ '/etc/init.d/hhvm-fastcgi', '/etc/init.d/hhvm' ]:
        ensure  => absent,
        require => Package['hhvm'],
    }

    file { '/etc/init/hhvm.conf':
        source  => 'puppet:///modules/beta/hhvm/hhvm.upstart',
        require => File['/etc/init.d/hhvm-fastcgi',
                        '/etc/init.d/hhvm',
                        '/etc/hhvm/server.hdf'],
    }

    service { 'hhvm':
        ensure   => running,
        provider => upstart,
        require  => File['/etc/init/hhvm.conf'],
    }
}
