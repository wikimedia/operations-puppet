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

    file { '/etc/init/xvfb.conf':
        content => template('xvfb/xvfb.conf.erb'),
        require => [ Package['xvfb'], User['xvfb'] ],
        notify  => Service['xvfb'],
    }

    service { 'xvfb':
        ensure   => running,
        provider => 'upstart',
        require  => File['/etc/init/xvfb.conf'],
    }
}
