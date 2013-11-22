# == Class: graphite::web
#
# Configures the Graphite webapp, a Django webapp for browsing metric data and
# constructing graphs. Configures Nginx as HTTP server / reverse proxy and
# uWSGI as the application server.
#
# === Parameters
#
# [*server_name*]
#   Name of virtual server. May contain wildcards.
#   See <http://nginx.org/en/docs/http/server_names.html>.
#   Defaults to '_', which is catch-all.
#
# [*uwsgi_processes*]
#   Number of uWSGI workers to run.
#
# [*memcached_size*]
#   Size of memcached store, in megabytes (default: 200).
#
class graphite::web(
    $server_name     = '_',
    $uwsgi_processes = 4,
    $memcached_size  = 200,
) {
    include ::graphite
    include ::passwords::graphite

    package { [ 'nginx-full', 'nginx-full-dbg' ]: }
    package { [ 'memcached', 'python-memcache' ]: }
    package { 'graphite-web': }

    file { '/etc/graphite/local_settings.py':
        content => template('graphite/local_settings.py.erb'),
        require => Package['graphite-web'],
    }

    file { '/etc/nginx/sites-available/graphite':
        content => template('graphite/graphite.nginx.erb'),
        require => Package['nginx-full'],
    }

    file { '/etc/nginx/sites-enabled':
        ensure  => directory,
        recurse => true,
        purge   => true,
        force   => true,
        require => Package['nginx-full'],
    }

    file { '/etc/nginx/sites-enabled/graphite':
        ensure => link,
        target => '/etc/nginx/sites-available/graphite',
        notify => Service['nginx'],
    }

    service { 'nginx':
        ensure   => running,
        enable   => true,
        provider => 'debian',
        require  => Package['nginx-full'],
    }

    file { [
        '/var/lib/graphite-web',
        '/var/log/graphite-web',
        '/var/run/graphite-web',
    ]:
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0755',
        require => Package['graphite-web'],
    }

    exec { 'graphite_syncdb':
        command     => '/usr/bin/python manage.py syncdb --noinput',
        cwd         => '/usr/share/pyshared/graphite',
        user        => 'www-data',
        subscribe   => File['/etc/graphite/local_settings.py'],
        refreshonly => true,
        require     => [
            Package['graphite-web', 'python-memcache'],
            File['/var/lib/graphite-web'],
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

    uwsgi::app { 'graphite-web':
        settings => {
            uwsgi => {
                'plugins'     => 'python',
                'socket'      => '/var/run/graphite-web/graphite-web.sock',
                'stats'       => '/var/run/graphite-web/graphite-web-stats.sock',
                'wsgi-file'   => '/usr/share/graphite-web/graphite.wsgi',
                'die-on-term' => true,
                'master'      => true,
                'processes'   => $uwsgi_processes,
            },
        },
        require => File['/var/run/graphite-web', '/var/log/graphite-web'],
    }
}
