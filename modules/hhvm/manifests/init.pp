# == Class hhvm
#
# Base class to run an hhvm mediawiki environment.
#
# This class will ensure that the hhvm packages and basic dirs are installed.
# It also ensures the FastCGI is in the desired state and can tweak
# configuration according to the needs of the dependent class.
#
class hhvm(
    $user  = 'www-data',
    $group = 'www-data',
) {
    requires_ubuntu('>= trusty')


    ## Packages

    package { 'hhvm':
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

    file { '/etc/hhvm/extensions.hdf':
        source => 'puppet:///modules/hhvm/extensions.hdf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

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
