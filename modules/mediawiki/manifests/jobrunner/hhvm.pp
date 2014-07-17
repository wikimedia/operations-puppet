# == Class: mediawiki::jobrunner::hhvm
#
# Installs and configures hhvm so that it's used to run all jobs
#
# This class will ensure that hhvm packages are installed, the fastcgi
# server is turned off and hhvm is providing /usr/bin/php via the
# alternatives mechanism. Please note that installation of the
# alternative will be taken care of by the debian package.
#
# This class should be included along with the mediawiki::jobrunner
# class that will install the runner upstart job and all the rest
# We also store the bytecode cache (which is persistent) in /run/hhvm
# which is in tmpfs as a bonus.
#
class mediawiki::jobrunner::hhvm {
    require ::mediawiki::hhvm

    # Ensure the fcgi server is stopped
    service { 'hhvm':
        ensure   => stopped,
        provider => 'upstart',
        reqire  => Class['::mediawiki::hhvm']
    }

    # ensure hhvm is the chosen runtime for /usr/bin/php
    alternatives::config{ 'php':
        path        => '/usr/bin/hhvm',
        require     => Package['hhvm']
    }

    file { '/etc/hhvm/config.hdf':
        ensure => present,
        source => 'puppet:///modules/mediawiki/hhvm/jobrunner.hhvm.hdf',
        before => Alternatives::Config['php'],
    }

    file { '/etc/hhvm/hhvm.ini':
        ensure => present,
        source => 'puppet:///modules/mediawiki/hhvm/jobrunner.hhvm.ini',
        before => Alternatives::Config['php'],
    }

}
