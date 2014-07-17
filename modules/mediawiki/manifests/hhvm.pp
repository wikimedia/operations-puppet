# == Class mediawiki::hhvm
#
# Base class to run an hhvm mediawiki environment.
#
# This class will ensure that the hhvm packages and basic dirs are installed.
# We assume the config files will be provided separatedly for now.
#
class mediawiki::hhvm {
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
        before  => Alternatives::Config['php'],
    }
}
