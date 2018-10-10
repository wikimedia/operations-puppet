# == Class: coal::web
#
# The web API for data collected by coal::processor.
#
# The API is exposed from, and used by, profile::webperf::site.
# Canonically at <https://performance.wikimedia.org>.
#
class coal::web {
    include ::coal::common

    require_package('python-flask')
    require_package('python-numpy')
    require_package('python-requests')

    file { '/var/cache/coal_web':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
    }

    systemd::tmpfile { 'coal_web':
        content => 'd /var/cache/coal_web 0755 www-data www-data 1d -',
    }

    uwsgi::app { 'coal':
        service_settings => '--die-on-term',
        settings         => {
            uwsgi => {
                'plugins'   => 'python',
                'socket'    => '/run/uwsgi/coal.sock',
                'wsgi-file' => '/srv/deployment/performance/coal/coal/coal_web.py',
                'callable'  => 'app',
                'master'    => true,
                'processes' => 8,
            },
        },
    }

    base::service_auto_restart { 'uwsgi-coal': }
}
