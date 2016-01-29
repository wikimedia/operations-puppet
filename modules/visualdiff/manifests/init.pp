# == Class: visualdiff
#
# This module provides a standalone visual diffing service.
class visualdiff {
    require_package([
        'nodejs',
        'npm',
        # These are required by canvas
        'libcairo2-dev',
        'libjpeg-dev',
        'libpango1.0-dev',
        'libgif-dev',
        # These are required to build canvas and uprightdiff.
        # They can be skipped once we get packaged versions
        # from elsewhere.
        'build-essential',
        'g++',
    ])

    group { 'visualdiff':
        ensure => present,
        system => true,
    }

    user { 'visualdiff':
        gid        => 'visualdiff',
        home       => '/srv/visualdiff',
        managehome => false,
        system     => true,
    }

    file { '/var/log/visualdiff':
        ensure => directory,
        owner  => 'visualdiff',
        group  => 'visualdiff',
        mode   => '0755',
    }

    file { '/etc/visualdiff':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    git::clone { 'integration/visualdiff':
        branch    => 'ruthenium',
        owner     => 'root',
        group     => 'wikidev',
        directory => '/srv/visualdiff',
    }

    git::clone { 'integration/uprightdiff':
        owner     => 'root',
        group     => 'wikidev',
        directory => '/srv/uprightdiff',
    }
}
