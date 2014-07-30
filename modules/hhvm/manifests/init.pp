# == Class: hhvm
#
# This module provisions HHVM -- an open-source, high-performance
# virtual machine for PHP.
#
# The layout of configuration files in /etc/hhvm is as follows:
#
#   /etc/hhvm
#   ├── config.hdf ........ HDF file for CLI mode
#   ├── php.ini ........... INI file for CLI mode
#   └── fastcgi/
#       ├── config.hdf .... HDF file for FastCGI mode
#       └── php.ini ....... INI file for FastCGI mode
#
class hhvm(
    $user  = 'www-data',
    $group = 'www-data',
) {
    requires_ubuntu('>= trusty')

    ## Packages

    package { [ 'hhvm', 'hhvm-dbg' ]:
        ensure => latest,
        before => Service['hhvm'],
    }

    package { [ 'hhvm-fss', 'hhvm-luasandbox', 'hhvm-wikidiff2' ]:
        ensure => latest,
        before => Service['hhvm'],
    }


    ## Service

    file { '/etc/default/hhvm':
        content => template('hhvm/hhvm.default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['hhvm'],
    }

    file { '/etc/init/hhvm.conf':
        source => 'puppet:///modules/hhvm/hhvm.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['hhvm'],
    }

    service { 'hhvm':
        ensure   => 'running',
        provider => 'upstart',
    }

    file { [ '/etc/hhvm', '/etc/hhvm/fastcgi' ]:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/sbin/hstr':
        source => 'puppet:///modules/hhvm/hstr',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        before => Service['hhvm'],
    }


    ## Run-time directories

    file { [ '/run/hhvm', '/var/log/hhvm' ]:
        ensure => directory,
        owner  => $user,
        group  => $group,
        mode   => '0755',
    }

    file { '/run/hhvm/cache':
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0750',
    }


    ## Config files

    file { '/etc/hhvm/config.hdf':
        content => template('hhvm/config.hdf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/etc/hhvm/php.ini':
        content => template('hhvm/php.ini.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/etc/hhvm/fastcgi/config.hdf':
        content => template('hhvm/fastcgi/config.hdf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['hhvm'],
    }

    file { '/etc/hhvm/fastcgi/php.ini':
        content => template('hhvm/fastcgi/php.ini.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['hhvm'],
    }
}
