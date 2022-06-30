# SPDX-License-Identifier: Apache-2.0
# == Define: uwsgi:app
#
# Provisions a uWSGI application server instance.
#
# === Parameters
#
# [*settings*]
#   Hash of hashes, representing the app configuration. Each key of the
#   top-level hash is used as a section in the app's ini file. If a second
#   level key has a value that is an Array, that key is repeated for each
#   value of the array
# [* core_limit *]
#   A string containing the core size limit to allow coredumps.
#   Values: 'unlimited', 'nG' (n is a number of Gigabytes), or '0' for no core.
#
# === Examples
#
#  uwsgi::app { 'graphite-web':
#    settings => {
#      uwsgi => {
#          'plugins'     => 'python',
#          'socket'      => '/var/run/graphite-web/graphite-web.sock',
#          'wsgi-file'   => '/usr/share/graphite-web/graphite.wsgi',
#          'master'      => true,
#          'processes'   => 4,
#          'env'         => ['MYSQL_HOST=localhost', 'STATSD_PREFIX=wat'],
#      },
#    },
#  }
#
define uwsgi::app(
    Wmflib::Ensure      $ensure             = present,
    Boolean             $enabled            = true,
    String              $service_settings   = '--die-on-term',
    String              $core_limit         = '0',
    Hash                $settings           = {},
    Array[Uwsgi::Route] $routes             = [],
    Hash                $extra_systemd_opts = {},
) {
    include uwsgi

    $basename = regsubst($title, '\W', '-', 'G')

    file { "/etc/uwsgi/apps-available/${basename}.ini":
        ensure  => $ensure,
        content => template('uwsgi/app.ini.erb'),
    }

    $inipath =  "/etc/uwsgi/apps-enabled/${basename}.ini"
    if $ensure == 'present' and $enabled {
        file { $inipath:
            ensure => link,
            target => "/etc/uwsgi/apps-available/${basename}.ini",
        }

        base::service_unit { "uwsgi-${title}":
            ensure    => present,
            systemd   => systemd_template('uwsgi'),
            subscribe => File["/etc/uwsgi/apps-available/${basename}.ini"],
        }

        nrpe::monitor_service { "uwsgi-${title}":
            ensure       => present,
            description  => "${title} uWSGI web app",
            nrpe_command => "/bin/systemctl status uwsgi-${title}",
            require      => Base::Service_unit["uwsgi-${title}"],
            notes_url    => "https://wikitech.wikimedia.org/wiki/Monitoring/Services/${title}",
        }
    } else {
        file { $inipath:
            ensure => absent,
        }

        base::service_unit { "uwsgi-${title}": # lint:ignore:wmf_styleguide
            ensure => absent,
        }

        nrpe::monitor_service { "uwsgi-${title}":
            ensure => absent,
        }
    }
}
