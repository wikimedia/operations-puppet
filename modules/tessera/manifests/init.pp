# == Class: tessera
#
# Tessera is a front-end interface for Graphite, which provides a large
# selection of presentations, layout, and interactivity options for
# building dashboards.
#
# The provisioning of a web server to reverse-proxy the tessera WSGI app
# is left to the caller. This module simply sets up tessera to listen on
# /run/uwsgi/tessera.sock.
#
# A minimal setup using Apache would look like this:
#
#  class role::tessera {
#    include ::apache::mod::uwsgi
#
#    class { 'tessera':
#      graphite_url => 'https://graphite.wikimedia.org',
#      secret_key   => '9IFf0HGWKAz5GYbIQHkWAr8WjbZC1r7PScFezYmXzyo',
#    }
#
#    apache::site { 'tessera.wikimedia.org':
#      content => template('apache/sites/tessera.wikimedia.org.erb'),
#    }
#  }
#
# ..with the Apache config file containing:
#
#  <Location />
#    uWSGIsocket /run/uwsgi/tessera.sock
#    SetHandler uwsgi-handler
#  </Location>
#
# === Parameters
#
# [*graphite_url*]
#   URL of Graphite backend. For example: 'https://graphite.wikimedia.org'.
#
# [*secret_key*]
#   A secret key for this Tessera installation.
#
# [*sqlalchemy_database_uri*]
#   A SQLAlchemy database URI pointing to the database Tessera should use.
#   Default: "sqlite:////var/lib/tessera/app.db".
#
# === Examples
#
#  class { 'tessera':
#    graphite_url            => 'https://graphite.wikimedia.org',
#    secret_key              => '9IFf0HGWKAz5GYbIQHkWAr8WjbZC1r7PScFezYmXzyo',
#    sqlalchemy_database_uri => 'postgresql://scott:tiger@localhost:5432/tessera',
#  }
#
class tessera(
    $graphite_url,
    $secret_key,
    $sqlalchemy_database_uri = 'sqlite:////var/lib/tessera/app.db',
) {
    require_package('python-flask-migrate')
    require_package('python-flask-sqlalchemy')
    require_package('python-requests')
    require_package('python-sqlalchemy')

    package { 'tessera':
        provider => 'trebuchet',
    }

    file { '/etc/tessera':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['tessera'],
    }

    file { '/var/lib/tessera':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
        before => Exec['tessera_create_db'],
    }

    file { '/etc/tessera/config.py':
        content => template('tessera/config.py.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Exec['tessera_create_db'],
        before  => Uwsgi::App['tessera'],
    }

    exec { 'tessera_create_db':
        command     => '/usr/bin/python -c "from tessera import db; db.create_all()"',
        cwd         => '/srv/deployment/tessera/tessera',
        environment => 'TESSERA_CONFIG=/etc/tessera/config.py',
        user        => 'www-data',
        refreshonly => true,
        require     => Package['tessera'],
        before      => Uwsgi::App['tessera'],
    }

    uwsgi::app { 'tessera':
        settings => {
            uwsgi => {
                'plugins'     => 'python',
                'env'         => 'TESSERA_CONFIG=/etc/tessera/config.py',
                'chdir'       => '/srv/deployment/tessera/tessera',
                'module'      => 'tessera',
                'socket'      => '/run/uwsgi/tessera.sock',
                'callable'    => 'app',
                'die-on-term' => true,
                'master'      => true,
                'processes'   => 8,
            },
        },
    }
}
