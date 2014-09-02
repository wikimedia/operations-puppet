# == Class: mediawiki::monitoring::errors
#
# Configures a metric module that listens on a UDP port for MediaWiki
# fatal and exception log messages and reports them to Ganglia.
#
# === Parameters
#
# [*listen_port*]
#   UDP port on which to listen for log data (default: 8423).
#
# [*statsd_host*]
#   StatsD server host (default: 'statsd').
#
# [*statsd_port*]
#   StatsD server port (default: 8125).
#
class mediawiki::monitoring::errors(
    $ensure      = present,
    $listen_port = 8423,
    $statsd_host = 'statsd',
    $statsd_port = 8125,
) {
    file { '/usr/local/bin/mwerrors':
        ensure => $ensure,
        source => 'puppet:///modules/mediawiki/monitoring/mwerrors.py',
        notify => Service['mwerrors'],
    }

    file { '/etc/init/mwerrors.conf':
        ensure  => $ensure,
        content => template('mediawiki/monitoring/mwerrors.upstart.conf.erb'),
        notify  => Service['mwerrors'],
    }

    service { 'mwerrors':
        ensure   => $ensure ? { present => running, absent => stopped },
        provider => upstart,
    }
}
