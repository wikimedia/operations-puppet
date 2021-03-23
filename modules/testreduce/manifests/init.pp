# == Class: testreduce
#
# This file provides the testreduce code repository
#
class testreduce(
    Boolean $install_node,
){

    if debian::codename::eq('stretch') {

        apt::repository { 'stretch-node10':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => 'stretch-wikimedia',
            components => 'component/node10',
            before     => Package['nodejs'],
        }

        $node_packages = ['nodejs', 'nodejs-dev', 'node-abbrev', 'node-ansi-regex',
                      'node-cacache', 'node-config-chain', 'node-glob', 'node-hosted-git-info',
                      'node-ini node-npm-package-arg', 'node-jsonstream',
                      'node-libnpx', 'node-lockfile', 'node-lru-cache',
                      'node-move-concurrently', 'node-normalize', 'package-data',
                      'node-gyp', 'node-resolve-from', 'node-npmlog', 'node-osenv',
                      'node-read-package-json', 'node-request', 'node-retry',
                      'node-rimraf', 'node-semver', 'node-sha', 'node-slide',
                      'node-strip-ansi', 'node-tar', 'node-boxen', 'node-which']

        $pinned_packages = join($node_packages, ' ')

        apt::pin { 'node10-stretch-wikimedia':
            package  => $pinned_packages,
            pin      => 'release a=stretch-wikimedia',
            priority => 1005,
            before   => Package['nodejs'],
        }
    }

    if $install_node {
        ensure_packages(['nodejs', 'npm'])
    }

    group { 'testreduce':
        ensure => present,
        system => true,
    }

    user { 'testreduce':
        gid        => 'testreduce',
        home       => '/srv/testreduce',
        managehome => false,
        system     => true,
    }

    file { '/var/log/testreduce':
        ensure => directory,
        owner  => 'testreduce',
        group  => 'testreduce',
        mode   => '0755',
    }

    file { '/etc/testreduce':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    git::clone { 'mediawiki/services/parsoid/testreduce':
        owner     => 'root',
        group     => 'wikidev',
        directory => '/srv/testreduce',
        # FIXME: Is this notification required?
        # There can be multiple services that might
        # be instantiated using the code from this
        # repository. The only way to notify all those
        # services would be hardcode all their names here.
        #
        # notify    => Service[$instance_name],
    }
}
