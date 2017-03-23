# == Class: visualdiff
#
# This module provides a standalone visual diffing service.
class visualdiff {

    # Fonts included for phantomjs rendering
    # of indic and other language wiki pages
    include ::mediawiki::packages::fonts

    # build-essential and g++ are required to build uprightdiff
    # They can be skipped once we get a packaged version # from elsewhere.
    $visualdiff_packages = [
        'nodejs',
        'npm',
        'uprightdiff',
        # TODO: Remove packages needed for building once
        # packaged version of uprightdiff is tested
        'build-essential',
        'g++',
        'libopencv-highgui-dev',
        'libboost-program-options-dev',
    ]

    require_package($visualdiff_packages)

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

    # visual-diff testreduce clients save the
    # parsoid and php parser screenshots and
    # the screenshot diff to this directory.
    file { '/srv/visualdiff/pngs':
        ensure => directory,
        owner  => 'testreduce',
        group  => 'testreduce',
        mode   => '0775',
    }

    git::clone { 'integration/uprightdiff':
        owner     => 'root',
        group     => 'wikidev',
        directory => '/srv/uprightdiff',
    }
}
