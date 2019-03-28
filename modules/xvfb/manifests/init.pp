# == Class: xvfb
#
# Configure a persistent Xvfb daemon.
#
# Xvfb (or X virtual framebuffer) is an X11 server that performs all
# graphical operations in memory, not showing any screen output.
#
# === Parameters
#
# [*display*]
#   X display number. Default: 99.
#
# [*resolution*]
#   Virtual framebuffer resolution, expressed as WIDTHxHEIGHTxDEPTH.
#   Default: '1024x768x24'.
#
# === Examples
#
#  class { 'xvfb':
#    display    => 85,
#    resolution => '800x600x16',
#  }
#
class xvfb(
    $display    = 99,
    $resolution = '1024x768x24',
) {
    package { 'xvfb':
        ensure => present,
    }

    group { 'xvfb':
        ensure => present,
    }

    user { 'xvfb':
        ensure => present,
        gid    => 'xvfb',
        shell  => '/bin/false',
        home   => '/nonexistent',
        system => true,
    }

    base::service_unit { 'xvfb':
        ensure         => present,
        refresh        => true,
        systemd        => systemd_template('xvfb'),
        service_params => {
            # enable is needed to have the service to start on boot time.
            enable     => true,
            hasstatus  => true,
            hasrestart => true,
        },
        require        => [
            Package['xvfb'],
            User['xvfb']
        ],
    }
}
