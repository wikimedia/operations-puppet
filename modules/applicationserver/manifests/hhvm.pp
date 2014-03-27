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

    # Hack: modify libmemcached10 package to remove spurious conflict with libmemcached6,
    # as has already been done upstream; see <https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=700091>.
    # Only needed while waiting for RT 7133.
    file { '/usr/local/sbin/repack-libmemcached10':
        source => 'puppet:///modules/applicationserver/hhvm/repack-libmemcached10',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    exec { '/usr/local/sbin/repack-libmemcached10':
        onlyif => '/usr/bin/dpkg-deb -I /var/cache/apt/archives/libmemcached10_1.0.8-1~wmf+precise1_amd64.deb 2>/dev/null | /bin/grep -q Conflicts',
        before => Package['hhvm-fastcgi'],
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


    # FIXME: This should be a parametrized template.
    file { '/etc/hhvm/server.hdf':
        source  => 'puppet:///modules/applicationserver/hhvm/server.hdf',
        require => Package['hhvm-fastcgi'],
        notify  => Service['hhvm'],
    }

    file { '/etc/init.d/hhvm-fastcgi':
        ensure  => absent,
        require => Package['hhvm-fastcgi'],
    }

    file { '/etc/init/hhvm':
        source  => 'puppet:///modules/applicationserver/hhvm/hhvm.upstart',
        require => File['/etc/init.d/hhvm-fastcgi', '/etc/hhvm/server.hdf'],
    }

    service { 'hhvm':
        ensure   => running,
        provider => upstart,
        require  => File['/etc/init/hhvm'],
    }
}
