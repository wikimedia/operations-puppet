# == Class: mathoid
#
# Mathoid is a nodejs-powered TeX-to-MathML/SVG conversion tool which runs as an
# HTTP service.
#
class mathoid {
    package { [ 'npm', 'phantomjs' ]:
        ensure => present,
    }

    git::clone { 'Math':
        origin    => 'https://gerrit.wikimedia.org/r/p/mediawiki/extensions/Math.git',
        directory => '/srv/Math',
    }

    exec { 'install mathoid':
        command => '/usr/bin/npm install',
        cwd     => '/srv/Math/mathoid',
        onlyif  => 'npm list --json | grep -q \'"missing": true\'',
        require => [
            Package['npm', 'phantomjs'],
            Git::Clone['Math'],
        ],
    }

    user { 'mathoid':
        ensure     => present,
        gid        => 'mathoid',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
    }

    group { 'mathoid':
        ensure => present,
    }

    file { '/etc/init/mathoid.conf':
        source => 'puppet:///modules/mathoid/mathoid.conf',
        require => [
            User['mathoid'],
            Exec['install mathoid'],
        ],
    }

    service { 'mathoid':
        ensure    => running,
        provider  => 'upstart',
        subscribe => File['/etc/init/mathoid.conf'],
    }
}
