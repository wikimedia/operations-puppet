# == Class: graphite::web
#
# Configures the Graphite webapp, a Django webapp for browsing metric data and
# constructing graphs. Configures Nginx as HTTP server / reverse proxy and
# uWSGI as the application server.
#
# === Parameters
#
# [*uwsgi_processes*]
#   Number of uWSGI workers to run.
#
# [*memcached_size*]
#   Size of memcached store, in megabytes (default: 200).
#
class graphite::web(
    $uwsgi_processes = 4,
    $memcached_size  = 200,
) {
    include ::graphite
    include ::passwords::graphite

    package { [ 'nginx-full', 'nginx-full-dbg' ]: }
    package { [ 'uwsgi', 'uwsgi-plugin-python' ]: }
    package { [ 'memcached', 'python-memcache' ]: }
    package { 'graphite-web': }

    file { '/etc/graphite/local_settings.py':
        content => template('graphite/local_settings.py.erb'),
        require => Package['graphite-web'],
    }

    exec { 'graphite_syncdb':
        command     => 'python manage.py syncdb --noinput',
        cwd         => '/usr/share/pyshared/graphite',
        user        => 'www-data',
        subscribe   => File['/etc/graphite/local_settings.py'],
        refreshonly => true,
        require     => [
            Package['graphite-web', 'python-memcache'],
            File['/var/lib/graphite/search_index'],
        ],
    }

    file { '/etc/memcached.conf':
        content => template('graphite/memcached.conf.erb'),
        require => Package['memcached'],
    }

    service { 'memcached':
        ensure    => running,
        enable    => true,
        require   => Package['memcached'],
        subscribe => File['/etc/memcached.conf'],
    }

    file { [ '/var/log/graphite-web', '/var/run/graphite-web' ]:
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0755',
        require => Package['graphite-web'],
    }

    file { '/var/lib/graphite/search_index':
        owner => 'www-data',
        group => 'www-data',
        mode  => '0664',
    }

    file { '/etc/init/graphite-web.conf':
        content => template('graphite/graphite-web.conf.erb'),
        require => Package['uwsgi-plugin-python'],
    }

    service { 'graphite-web':
        ensure    => running,
        provider  => upstart,
        require   => File['/var/run/graphite-web', '/var/log/graphite-web'],
        subscribe => File['/etc/init/graphite-web.conf'],
    }
}
