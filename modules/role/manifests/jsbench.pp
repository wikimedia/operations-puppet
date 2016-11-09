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

    # it's chromium on Debian but chromium-browser on Ubuntu (T141023)
    if os_version('debian >= jessie') {
        require_package('chromium')
    } else {
        require_package('chromium-browser')
    }

    # 1366x768 is the most common display resolution, according
    # to http://gs.statcounter.com/.
    class { 'xvfb':
        resolution => '1366x768x24',
    }

    file { '/srv/profile':
        ensure => directory,
    }

    ferm::service { 've-xvfb':
        proto  => 'tcp',
        port   => '6099',
        srange => '$PRODUCTION_NETWORKS',
    }

    user { 'jsbench':
        ensure     => present,
        comment    => 'Chromium service user for jsbench',
        home       => '/srv/profile/jsbench',
        system     => true,
        managehome => true,
        require    => File['/srv/profile'],
    }

    file { '/usr/local/bin/jsbench':
        source => 'puppet:///modules/role/jsbench/jsbench',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    if $::initsystem == 'upstart' {
        file { '/etc/init/jsbench-browser.conf':
            ensure => present,
            source => 'puppet:///modules/role/jsbench/upstart',
            mode   => '0444',
        }
    }

    if $::initsystem == 'systemd' {
        file { '/etc/systemd/system/jsbench-browser.service':
            ensure => present,
            source => 'puppet:///modules/role/jsbench/systemd',
            mode   => '0444',
        }
    }

    file { '/usr/local/share/jsbench':
        source  => 'puppet:///modules/role/jsbench/benchmarks',
        recurse => true,
    }
}
