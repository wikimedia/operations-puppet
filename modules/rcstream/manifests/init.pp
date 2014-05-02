# == Class: rcstream
#
# This module configures rcstream, a simple Upstart / Python / Nginx
# stack that forwards 'rc' events from Redis to WebSocket clients.
#
# === Parameters
#
# [*redis*]
#   Address of Redis server that is publishing the events,
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
#  class { '::rcstream':
#    redis => 'rcstream.eqiad.wmnet:6379',
#    iface => '127.0.0.1',
#    ports => [ 10080, 10081, 10082 ],
#  }
#
class rcstream(
    $ports,
    $ensure = present,
    $redis  = '127.0.0.1:6379',
    $iface  = '0.0.0.0',
) {
    if versioncmp($::lsbdistrelease, '14.04') < 0 {
        fail('requires 14.04+')
    }

    group { 'rcstream':
        ensure => present,
    }

    user { 'rcstream':
        ensure     => present,
        gid        => 'rcstream',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
    }

    package { [ 'python-socketio', 'python-redis' ]:
        ensure => $ensure,
        before => Service['rcstream'],
    }

    file { '/usr/local/bin/rcstream':
        ensure => $ensure,
        source => 'puppet:///modules/rcstream/rcstream',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Service['rcstream'],
    }

    file { '/usr/local/sbin/rcstreamctl':
        ensure => $ensure,
        source => 'puppet:///modules/rcstream/rcstreamctl',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Service['rcstream'],
    }

    file { '/etc/default/rcstream':
        ensure  => $ensure,
        content => template('rcstream/rcstream.default.erb'),
        before  => Service['rcstream'],
    }

    file { '/etc/init/rcstream':
        ensure  => $ensure,
        source  => 'puppet:///modules/rcstream/upstart',
        before  => Service['rcstream'],
        recurse => true,
        purge   => true,
        force   => true,
    }

    service { 'rcstream':
        ensure   => 'running',
        provider => 'base',
        restart  => '/usr/local/sbin/rcstreamctl restart',
        start    => '/usr/local/sbin/rcstreamctl start',
        status   => '/usr/local/sbin/rcstreamctl status',
        stop     => '/usr/local/sbin/rcstreamctl stop',
    }
}
