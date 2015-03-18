# == Class: graphite::web
#
# Configures the Graphite webapp, a Django webapp for browsing metric data and
# constructing graphs, with uWSGI as the application server.
#
# === Parameters
#
# [*uwsgi_processes*]
#   Number of uWSGI workers to run (default: 8).
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
# [*storage_dir*]
#   Carbon storage directory. This is where the app will look for whisper
#   databases.
#
# [*documentation_url*]
#   Overrides the Documentation link used in the header of the Graphite
#   Composer (default: 'http://graphite.readthedocs.org/').
#
# [*cors_origins*]
#   An optional array of HTTP Origin header values or regexp patterns
#   for which graphite-web should set CORS headers.
#
class graphite::web(
    $admin_pass,
    $secret_key,
    $storage_dir,
    $uwsgi_processes   = 8,
    $memcached_size    = 200,
    $admin_user        = 'admin',
    $documentation_url = 'http://graphite.readthedocs.org/',
    $cors_origins      = undef,
) {
    include ::graphite

    package { ['memcached', 'python-memcache', 'graphite-web']: }

    file { '/etc/graphite/cors.py':
        source  => 'puppet:///modules/graphite/cors.py',
        require => Package['graphite-web'],
        notify  => Service['uwsgi'],
    }

    file { '/etc/graphite/local_settings.py':
        content => template('graphite/local_settings.py.erb'),
        require => Package['graphite-web'],
        notify  => Service['uwsgi'],
    }


    file { [
        '/var/lib/graphite-web',
        '/var/log/graphite-web',
    ]:
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0755',
        require => Package['graphite-web'],
    }

    exec { 'graphite_syncdb':
        command     => '/usr/bin/graphite-manage syncdb --noinput',
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
                'socket'      => '/run/uwsgi/graphite-web.sock',
                'stats'       => '/run/uwsgi/graphite-web-stats.sock',
                'wsgi-file'   => '/usr/share/graphite-web/graphite.wsgi',
                'die-on-term' => true,
                'master'      => true,
                'processes'   => $uwsgi_processes,
            },
        },
        require  => File['/var/log/graphite-web'],
    }

    file { '/usr/local/sbin/graphite-index':
        source  => 'puppet:///modules/graphite/graphite-index',
        mode    => '0555',
        require => Uwsgi::App['graphite-web'],
    }

    file { '/usr/local/sbin/graphite-auth':
        source  => 'puppet:///modules/graphite/graphite-auth',
        mode    => '0555',
        require => Uwsgi::App['graphite-web'],
    }

    cron { 'update_graphite_index':
        command => '/usr/local/sbin/graphite-index',
        user    => 'www-data',
        hour    => '*/1',
        require => File['/usr/local/sbin/graphite-index'],
    }

    exec { 'create_graphite_admin':
        command => "/usr/local/sbin/graphite-auth set ${admin_user} ${admin_pass}",
        unless  => "/usr/local/sbin/graphite-auth check ${admin_user} ${admin_pass}",
        require => File['/usr/local/sbin/graphite-auth'],
    }

    file { '/etc/logrotate.d/graphite-web':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/graphite/graphite-web-logrotate',
        require => File['/var/log/graphite-web'],
    }

}
