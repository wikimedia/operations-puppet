# == Class mediawiki::hhvm
#
# Base class to run an hhvm mediawiki environment.
#
# This class will ensure that the hhvm packages and basic dirs are installed.
# It also ensures the FastCGI is in the desired state and can tweak
# configuration according to the needs of the dependent class.
#
class mediawiki::hhvm(
    $ini_overrides = {
        'max_execution_time' => 180,
    },
    $service       = 'running'
) {
    # Install hhvm and all needed packages
    include mediawiki::packages::hhvm

    file { '/etc/hhvm':
        ensure  => directory,
        mode    => '0555',
        require => Package['hhvm']
    }

    file { '/run/hhvm':
        ensure  => directory,
        owner   => 'apache',
        group   => 'apache',
        mode    => '0755',
        require => Class['mediawiki::users'],
    }

    # This directory contains the bytecode cache and should not be
    # world accessible
    file { '/run/hhvm/cache':
        ensure  => directory,
        owner   => 'apache',
        group   => 'apache',
        mode    => '0750',
        before  => File['hhvm_config_ini'],
    }

    file { '/etc/hhvm/config.hdf':
        ensure => present,
        source => 'puppet:///modules/mediawiki/hhvm/jobrunner.hhvm.hdf',
    }

    file { 'hhvm_config_ini':
        path    => '/etc/hhvm/php.ini',
        ensure  => present,
        content => template('mediawiki/hhvm/hhvm.ini.erb'),
        require => Package['hhvm'],
    }

    # Ensure the fcgi server is stopped
    service { 'hhvm':
        ensure   => $service,
        provider => 'upstart',
        require  => Class['::mediawiki::packages::hhvm'],
    }
}
