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
# [*remote_user_auth*]
#   If true, enable authentication via REMOTE_USER.
#   See <https://docs.djangoproject.com/en/1.8/howto/auth-remote-user/>.
#
# [*cors_origins*]
#   An optional array of HTTP Origin header values or regexp patterns
#   for which graphite-web should set CORS headers.
#
# [*cluster_servers*]
#   An optional array of servers running graphite-web to be queried for
#   metrics.
#
# [*uwsgi_max_request_duration_seconds*]
#   If specified, have uwsgi kill a worker that takes longer than this to
#   execute a request.
#
# [*uwsgi_max_request_rss_megabytes*]
#   If specified, have uwsgi kill a worker whose RSS exceeds this value.
class graphite::web(
    $admin_pass,
    $secret_key,
    $storage_dir,
    $uwsgi_processes   = 8,
    $memcached_size    = 200,
    $admin_user        = 'admin',
    $documentation_url = 'http://graphite.readthedocs.org/',
    $remote_user_auth  = false,
    $cors_origins      = undef,
    $cluster_servers   = undef,
    $uwsgi_max_request_duration_seconds = undef,
    $uwsgi_max_request_rss_megabytes = undef,
) {
    include ::graphite

    validate_bool($remote_user_auth)

    require_package('memcached')
    require_package('python-memcache')
    require_package('libapache2-mod-uwsgi')

    # graphite >= 1.0 is in backports (>= stretch)
    package { 'graphite-web':
        ensure          => 'present',
        install_options => ['-t', "${::lsbdistcodename}-backports"],
    }

    file { '/etc/graphite/cors.py':
        source  => 'puppet:///modules/graphite/cors.py',
        require => Package['graphite-web'],
        notify  => Service['uwsgi-graphite-web'],
    }

    file { '/etc/graphite/local_settings.py':
        content => template('graphite/local_settings.py.erb'),
        require => Package['graphite-web'],
        notify  => Service['uwsgi-graphite-web'],
    }


    file { [ '/var/lib/graphite-web', '/var/log/graphite-web' ]:
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0755',
        require => Package['graphite-web'],
    }

    # django 1.9 compat, remove once the jessie -> stretch migration is completed
    $syncdb_command = $::lsbdistcodename ? {
        stretch  => '/usr/bin/graphite-manage migrate --run-syncdb --noinput',
        default  => '/usr/bin/graphite-manage syncdb --noinput',
    }

    exec { 'graphite_syncdb':
        command   => $syncdb_command,
        user      => 'www-data',
        subscribe => File['/etc/graphite/local_settings.py'],
        creates   => '/var/lib/graphite-web/graphite.db',
        require   => [
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
            # uwsgi::app will happily generate a config with 'key=undef' in the ini file.
            # So, some messy stuff to only include our optional configuration settings iff
            # they are provided.
            uwsgi => merge({
                'plugins'   => 'python',
                'socket'    => '/run/uwsgi/graphite-web.sock',
                'stats'     => '/run/uwsgi/graphite-web-stats.sock',
                'wsgi-file' => '/usr/share/graphite-web/graphite.wsgi',
                'master'    => true,
                'processes' => $uwsgi_processes,
            },
            if $uwsgi_max_request_duration_seconds != undef  { {'harakiri' => $uwsgi_max_request_duration_seconds} },
            if $uwsgi_max_request_rss_megabytes != undef     { {'evil-reload-on-rss' => $uwsgi_max_request_rss_megabytes} })
        },
        routes   => [ # do not cache renders
            {'route' => '^/render', 'action' => 'delheader:Cache-Control'},
            {'route' => '^/render', 'action' => 'addheader:Cache-Control: no-store'},
        ],
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
        hour    => '*',
        minute  => '*/5',
        require => File['/usr/local/sbin/graphite-index'],
    }

    exec { 'create_graphite_admin':
        command => "/usr/local/sbin/graphite-auth set ${admin_user} ${admin_pass}",
        unless  => "/usr/local/sbin/graphite-auth check ${admin_user} ${admin_pass}",
        user    => 'www-data',
        require => File['/usr/local/sbin/graphite-auth'],
    }

    logrotate::rule { 'graphite-web':
        file_glob   => '/var/log/graphite-web/*.log',
        frequency   => 'daily',
        compress    => true,
        size        => '100M',
        rotate      => 3,
        missing_ok  => true,
        post_rotate => '/usr/sbin/service uwsgi-graphite-web restart > /dev/null',
    }

}
