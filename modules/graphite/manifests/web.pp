# == Class: graphite::web
#
# Configures the Graphite webapp, a Django webapp for browsing metric data and
# constructing graphs.
#
# === Parameters
#
# [*memcached_size*]
#   Size of memcached store, in megabytes (default: 200).
#
class graphite::web(
    $memcached_size = 200,
) {
    include ::graphite

    package { 'graphite-web': }

    file { '/etc/graphite/local_settings.py':
        content => template('graphite/local_settings.py.erb'),
        require => Package['graphite-web'],
    }

    package { 'memcached': }

    file { '/etc/memcached.conf':
        content => template('graphite/memcached.conf.erb'),
    }

    service { 'memcached':
        ensure    => running,
        enable    => true,
        require   => Package['memcached'],
        subscribe => File['/etc/memcached.conf'],
    }
}
