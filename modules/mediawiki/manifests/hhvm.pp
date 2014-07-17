# == Class mediawiki::hhvm
#
# Base class to run an hhvm mediawiki environment.
#
# This class will ensure that the hhvm packages and basic dirs are installed.
# We assume the config files will be provided separatedly for now.
#
class mediawiki::hhvm {
    include mediawiki::packages::hhvm

    file { '/etc/hhvm':
        ensure  => directory,
        mode    => '0555',
        require => Package['hhvm'],
    }

    file { '/run/hhvm':
        ensure  => directory,
        owner   => 'apache',
        group   => 'apache',
        mode    => '0755',
        require => Class['mediawiki::users'],
    }

    # This directory contains the bytecode cache and should not be
    # world-accessible
    file { '/run/hhvm/cache':
        ensure  => directory,
        owner   => 'apache',
        group   => 'apache',
        mode    => '0750',
        before  => Alternatives::Config['php'],
    }
}
