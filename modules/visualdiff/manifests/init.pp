# SPDX-License-Identifier: Apache-2.0
# == Class: visualdiff
#
# This module provides a standalone visual diffing service.
class visualdiff {

    $visualdiff_packages = [
        'nodejs',
        'npm',
        'uprightdiff',
    ]

    ensure_packages($visualdiff_packages)

    systemd::sysuser { 'visualdiff':
        home_dir => '/srv/visualdiff',
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
        owner     => 'root',
        group     => 'wikidev',
        directory => '/srv/visualdiff',
        before    => File['/srv/visualdiff/pngs'],
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

    file { '/srv/visualdiff/testreduce':
        ensure => directory,
        owner  => 'root',
        group  => 'wikidev',
    }

    # create an empty testrun.ids but only if it does not exist
    # don't change content in existing file (T215049)
    file { '/srv/visualdiff/testreduce/testrun.ids':
        ensure  => present,
        replace => false,
        content => 'puppet-init',
        owner   => 'testreduce',
        group   => 'testreduce',
        mode    => '0775',
        require => File['/srv/visualdiff/testreduce'],
    }
}
