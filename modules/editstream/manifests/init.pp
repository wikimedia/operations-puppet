# == Class: editstream
#
# This module configures EditStream, a simple Upstart / Python / Nginx
# stack that forwards 'edits' events from Redis to WebSocket clients.
# See this module's README file for more details.
#
# === Parameters
#
# [*redis*]
#   Address of Redis server that is publishing edit events,
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
#  class { '::editstream':
#    redis => 'editstream.eqiad.wmnet:6379',
#    iface => '127.0.0.1',
#    ports => [ 10080, 10081, 10082 ],
#  }
#
class editstream(
    $ports,
    $ensure = present,
    $redis  = '127.0.0.1:6379',
    $iface  = '0.0.0.0',
) {
    if versioncmp($::lsbdistrelease, '14.04') < 0 {
        fail('requires 14.04+')
    }

    group { 'editstream':
        ensure => present,
    }

    user { 'editstream':
        ensure     => present,
        gid        => 'editstream',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
    }

    package { [ 'python-socketio', 'python-redis' ]:
        ensure => $ensure,
        before => Service['editstream'],
    }

    file { '/usr/local/bin/editstream':
        ensure => $ensure,
        source => 'puppet:///modules/editstream/editstream',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Service['editstream'],
    }

    file { '/usr/local/sbin/editstreamctl':
        ensure => $ensure,
        source => 'puppet:///modules/editstream/editstreamctl',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Service['editstream'],
    }

    file { '/etc/default/editstream':
        ensure  => $ensure,
        content => template('editstream/editstream.default.erb'),
        before  => Service['editstream'],
    }

    file { '/etc/init/editstream':
        ensure  => $ensure,
        source  => 'puppet:///modules/editstream/upstart',
        before  => Service['editstream'],
        recurse => true,
        purge   => true,
        force   => true,
    }

    service { 'editstream':
        ensure   => 'running',
        provider => 'base',
        restart  => '/usr/local/sbin/editstreamctl restart',
        start    => '/usr/local/sbin/editstreamctl start',
        status   => '/usr/local/sbin/editstreamctl status',
        stop     => '/usr/local/sbin/editstreamctl stop',
    }
}
