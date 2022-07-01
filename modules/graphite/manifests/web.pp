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
    String              $admin_pass,
    String              $secret_key,
    Stdlib::Unixpath    $storage_dir,
    Integer             $uwsgi_processes                    = 8,
    Integer             $memcached_size                     = 200,
    String              $admin_user                         = 'admin',
    String              $documentation_url                  = 'http://graphite.readthedocs.org/',
    Boolean             $remote_user_auth                   = false,
    Array[String]       $cors_origins                       = [],
    Array[Stdlib::Host] $cluster_servers                    = [],
    Optional[Integer]   $uwsgi_max_request_duration_seconds = undef,
    Optional[Integer]   $uwsgi_max_request_rss_megabytes    = undef,
) {
    include graphite

    ensure_packages('memcached')
    ensure_packages('python3-memcache')
    ensure_packages('libapache2-mod-uwsgi')
    ensure_packages('graphite-web')

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

    $syncdb_command = '/usr/bin/graphite-manage migrate --run-syncdb --noinput'

    exec { 'graphite_syncdb':
        command   => $syncdb_command,
        user      => 'www-data',
        subscribe => File['/etc/graphite/local_settings.py'],
        creates   => '/var/lib/graphite-web/graphite.db',
        require   => [
            Package['graphite-web', 'python3-memcache'],
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
                'plugins'     => 'python3',
                'socket'      => '/run/uwsgi/graphite-web.sock',
                'stats'       => '/run/uwsgi/graphite-web-stats.sock',
                'wsgi-file'   => '/usr/share/graphite-web/graphite.wsgi',
                'master'      => true,
                'processes'   => $uwsgi_processes,
                'buffer-size' => 8192, # bump request buffer space T292877
            },
            # Change settings module explicitly to work around https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=995461
            if debian::codename::ge('bullseye')  { {'env' => 'GRAPHITE_SETTINGS_MODULE=local_settings'} },
            if $uwsgi_max_request_duration_seconds != undef  { {'harakiri' => $uwsgi_max_request_duration_seconds} },
            if $uwsgi_max_request_rss_megabytes != undef     { {'evil-reload-on-rss' => $uwsgi_max_request_rss_megabytes} })
        },
        routes   => [ # do not cache renders
            {'route' => '^/render', 'action' => 'delheader:Cache-Control'},
            {'route' => '^/render', 'action' => 'addheader:Cache-Control: no-store'},
        ],
        require  => File['/var/log/graphite-web'],
    }

    profile::auto_restarts::service { 'uwsgi-graphite-web': }

    file { '/usr/local/sbin/graphite-index':
        source  => "puppet:///modules/graphite/graphite-index.${::lsbdistcodename}.py",
        mode    => '0555',
        require => Uwsgi::App['graphite-web'],
    }

    file { '/usr/local/sbin/graphite-auth':
        source  => "puppet:///modules/graphite/graphite-auth.${::lsbdistcodename}.py",
        mode    => '0555',
        require => Uwsgi::App['graphite-web'],
    }

    systemd::timer::job { 'update_graphite_index':
        ensure      => present,
        description => 'Regular jobs to generate the index file',
        user        => 'www-data',
        command     => '/usr/local/sbin/graphite-index',
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* *:0/5:00'},
        require     => File['/usr/local/sbin/graphite-index'],
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
