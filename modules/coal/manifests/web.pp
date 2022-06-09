# SPDX-License-Identifier: Apache-2.0
# == Class: coal::web
#
# The web API for data collected by coal::processor.
#
# The API is exposed from, and used by, profile::webperf::site.
# Canonically at <https://performance.wikimedia.org>.
#
class coal::web {
    include ::coal::common

    ensure_packages(['python3-flask', 'python3-numpy', 'python3-requests', 'python3-cachelib'])

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
        settings         => {
            uwsgi => {
                'plugins'   => 'python3',
                'socket'    => '/run/uwsgi/coal.sock',
                'wsgi-file' => '/srv/deployment/performance/coal/coal/coal_web.py',
                'callable'  => 'app',
                'master'    => true,
                'processes' => 8,
            },
        },
    }

    profile::auto_restarts::service { 'uwsgi-coal': }
}
