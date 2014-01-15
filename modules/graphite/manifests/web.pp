# == Class: graphite::web
#
# Configures the Graphite webapp, a Django webapp for browsing metric data and
# constructing graphs, with uWSGI as the application server.
#
# === Parameters
#
# [*uwsgi_processes*]
#   Number of uWSGI workers to run.
#
# [*memcached_size*]
#   Size of memcached store, in megabytes (default: 200).
#
# [*admin_user*]
#   Username for Django admin account (default: 'admin').
#
# [*admin_pass*]
#   Password for Django admin account.
#
# [*secret_key*]
#   This is used to provide cryptographic signing, and should be set to a
#   unique, unpredictable value.
#
# [*documentation_url*]
#   Overrides the Documentation link used in the header of the Graphite
#   Composer (default: 'http://graphite.readthedocs.org/').
#
class graphite::web(
    $admin_pass,
    $secret_key,
    $uwsgi_processes   = 4,
    $memcached_size    = 200,
    $admin_user        = 'admin',
    $documentation_url = 'http://graphite.readthedocs.org/',
) {
    include ::graphite

    package { [ 'memcached', 'python-memcache' ]: }
    package { 'graphite-web': }

    file { '/etc/graphite/local_settings.py':
        content => template('graphite/local_settings.py.erb'),
        require => Package['graphite-web'],
        notify  => Service['uwsgi'],
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
        require  => File['/var/run/graphite-web', '/var/log/graphite-web'],
    }

    file {
        '/sbin/graphite-index':
            source  => 'puppet:///modules/graphite/graphite-index',
            mode    => '0755';
            require => Uwsgi::App['graphite-web'];
        '/sbin/graphite-auth':
            source  => 'puppet:///modules/graphite/graphite-auth',
            mode    => '0755';
            require => Uwsgi::App['graphite-web'];
    }

    cron { 'update_graphite_index':
        command => '/sbin/graphite-index',
        user    => 'www-data',
        hour    => '*/1',
    }

    exec { 'create_graphite_admin':
        command => "/sbin/graphite-auth set ${admin_user} ${admin_pass}",
        unless  => "/sbin/graphite-auth check ${admin_user} ${admin_pass}",
        require => File['/sbin/graphite-auth'],
    }
}
