# SPDX-License-Identifier: Apache-2.0
class profile::mirrors {
    include profile::mirrors::serve

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
        ensure => absent,
    }

    # export age of mirrors to Prometheus
    prometheus::node_file_age { 'mirror_age_metrics':
        ensure  => absent,
        paths   => ['/srv/mirrors/debian', '/srv/mirrors/ubuntu'],
        outfile => '/var/lib/prometheus/node.d/mirror-age.prom',
    }
}
