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

    apt::repository { 'boost_backports':
        uri        => 'http://ppa.launchpad.net/mapnik/boost/ubuntu',
        dist       => 'precise',
        components => 'main',
        keyfile    => 'puppet:///files/misc/boost-backports.key',
        before     => Package['hhvm-fastcgi'],
    }

    package { 'hhvm-fastcgi':
        ensure  => present,
        require => Apache_module['apache_mod_fastcgi_for_hhvm'],
    }

    package { 'libapache2-mod-fastcgi':
        ensure => present,
        before => Apache_module['apache_mod_fastcgi_for_hhvm'],
    }

    apache_module { 'apache_mod_rewrite_for_hhvm': name => 'rewrite', }
    apache_module { 'apache_mod_actions_for_hhvm': name => 'actions', }
    apache_module { 'apache_mod_alias_for_hhvm': name => 'alias', }
    apache_module { 'apache_mod_fastcgi_for_hhvm': name => 'fastcgi', }

    file { '/var/run/hhvm':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
    }

    # FIXME: This should be a parametrized template.
    file { '/etc/hhvm/server.hdf':
        source  => 'puppet:///modules/applicationserver/hhvm/server.hdf',
        require => [ Package['hhvm-fastcgi'], File['/var/run/hhvm'] ],
        notify  => Service['hhvm'],
    }

    file { [ '/etc/init.d/hhvm-fastcgi', '/etc/init.d/hhvm' ]:
        ensure  => absent,
        require => Package['hhvm-fastcgi'],
    }

    file { '/etc/init/hhvm.conf':
        source  => 'puppet:///modules/applicationserver/hhvm/hhvm.upstart',
        require => File['/etc/init.d/hhvm-fastcgi', '/etc/init.d/hhvm', '/etc/hhvm/server.hdf'],
    }

    service { 'hhvm':
        ensure   => running,
        provider => upstart,
        require  => File['/etc/init/hhvm.conf'],
    }
}
