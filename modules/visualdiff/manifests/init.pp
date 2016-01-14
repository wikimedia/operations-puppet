# == Class: visualdiff
#
# This module provides a standalone visual diffing service.
class visualdiff {
    require_package('nodejs')
    require_package('npm')

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

    # FIXME: This repo doesn't exist right now.
    # It is only available on github
    git::clone { 'mediawiki/services/parsoid/visualdiff':
        ensure    => latest,
        owner     => 'root',
        group     => 'wikidev',
        directory => '/srv/visualdiff',
    }

    git::clone { 'integration/uprightdiff':
        ensure    => latest,
        owner     => 'root',
        group     => 'wikidev',
        directory => '/srv/uprightdiff',
    }
}
