# == Class: changes
#
# This module configures Changes, a simple Upstart / Python / Nginx
# stack that forwards 'changes' events from Redis to WebSocket clients.
#
# === Parameters
#
# [*redis*]
#   Address of Redis server that is publishing change events,
#   in 'host:port' format. Defaults to '127.0.0.1:6379'.
#
# [*iface*]
#   Interface that WebSocket server should bind to.
#   Defaults to '0.0.0.0'.
#
# [*ports*]
#   An array of port numbers. A WebSocket server instance
#   will be spawned for each port.
#
# === Examples
#
#  class { '::changes':
#    redis => 'changes.eqiad.wmnet:6379',
#    iface => '127.0.0.1',
#    ports => [ 10080, 10081, 10082 ],
#  }
#
class changes(
    $ports,
    $ensure = present,
    $redis  = '127.0.0.1:6379',
    $iface  = '0.0.0.0',
) {
    if versioncmp($::lsbdistrelease, '14.04') < 0 {
        fail('requires 14.04+')
    }

    group { 'changes':
        ensure => present,
    }

    user { 'changes':
        ensure     => present,
        gid        => 'changes',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
    }

    package { [ 'python-socketio', 'python-redis' ]:
        ensure => $ensure,
        before => Service['changes'],
    }

    file { '/usr/local/bin/changes':
        ensure => $ensure,
        source => 'puppet:///modules/changes/changes',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Service['changes'],
    }

    file { '/usr/local/sbin/changesctl':
        ensure => $ensure,
        source => 'puppet:///modules/changes/changesctl',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Service['changes'],
    }

    file { '/etc/default/changes':
        ensure  => $ensure,
        content => template('changes/changes.default.erb'),
        before  => Service['changes'],
    }

    file { '/etc/init/changes':
        ensure  => $ensure,
        source  => 'puppet:///modules/changes/upstart',
        before  => Service['changes'],
        recurse => true,
        purge   => true,
        force   => true,
    }

    service { 'changes':
        ensure   => 'running',
        provider => 'base',
        restart  => '/usr/local/sbin/changesctl restart',
        start    => '/usr/local/sbin/changesctl start',
        status   => '/usr/local/sbin/changesctl status',
        stop     => '/usr/local/sbin/changesctl stop',
    }
}
