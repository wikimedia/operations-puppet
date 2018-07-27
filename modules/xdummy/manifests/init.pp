# == Class: xdummy
#
# Configure a persistent Xdummy daemon.
#
# Xdummy is an X11 server that performs all graphical operations,
# including GLX, on a virtual display.
#
# === Parameters
#
# [*display*]
#   X display number. Default: 95.
#
# === Examples
#
#  class { 'xdummy':
#    display    => 86
#  }
#
class xdummy(
    $display    = 95
) {
    package { 'xorg':
        ensure => present,
    }

    package { 'xpra':
        ensure => present,
    }

    group { 'xdummy':
        ensure => present,
    }

    user { 'xdummy':
        ensure => present,
        gid    => 'xdummy',
        shell  => '/bin/false',
        home   => '/nonexistent',
        system => true,
    }

    systemd::service { 'xdummy':
        ensure  => present,
        restart => true,
        content => systemd_template('xdummy'),
        require => [
            Package['Xorg'],
            Package['xpra'],
            User['xdummy']
        ],
    }
}
