# == Class: role::jsbench
#
# Sets up a Javascript performance testing rig with a headless
# Chromium instance that supports remote debugging.
#
class role::jsbench {
    # jsbench is a CLI tool for benchmarking Javascript performance.
    # It uses `autobahn` and `twisted` for WebSocket support, which
    # it needs so it can speak Chrome's remote debugging protocol.
    # It uses `numpy` to calculate summary statistics.
    require_package('python-autobahn', 'python-twisted', 'python-numpy')
    require_package('chromium-browser')

    # 1366x768 is the most common display resolution, according
    # to http://gs.statcounter.com/.
    class { 'xvfb':
        resolution => '1366x768x24',
    }

    file { '/srv/profile':
        ensure => directory,
    }

    user { 'jsbench':
        ensure     => present,
        comment    => 'Chromium service user for jsbench',
        home       => '/srv/profile/jsbench',
        managehome => true,
        require    => File['/srv/profile'],
    }

    file { '/usr/local/bin/jsbench':
        source => 'puppet:///files/jsbench/jsbench',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/etc/init/jsbench-browser.conf':
        ensure => present,
        source => 'puppet:///files/jsbench/upstart',
        mode   => '0444',
    }

    file { '/usr/local/share/jsbench':
        source  => 'puppet:///files/jsbench/benchmarks',
        recurse => true,
    }
}
