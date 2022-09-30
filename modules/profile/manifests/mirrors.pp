# SPDX-License-Identifier: Apache-2.0
class profile::mirrors {
    include profile::mirrors::serve
    include profile::mirrors::debian
    include profile::mirrors::openstack
    include profile::mirrors::tails
    include profile::mirrors::ubuntu

    $homedir = '/var/lib/mirror'

    user { 'mirror':
        ensure     => present,
        gid        => 'mirror',
        home       => $homedir,
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    group { 'mirror':
        ensure => present,
        name   => 'mirror',
        system => true,
    }

    file { '/srv/mirrors':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    # monitoring for Debian/Ubuntu mirrors being in sync with upstream
    nrpe::plugin { 'check_apt_mirror':
        source => 'puppet:///modules/profile/mirrors/check_apt_mirror';
    }
}
