# == Define: uwsgi:app
#
# Provisions a uWSGI application server instance.
#
# === Parameters
#
# [*settings*]
#   Hash of hashes, representing the app configuration. Each key of the
#   top-level hash is used as a section in the app's ini file.
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
#      },
#    },
#  }
#
define uwsgi::app(
    $settings,
    $ensure   = present,
    $enabled  = true,
) {
    include ::uwsgi

    $basename = regsubst($title, '\W', '-', 'G')

    if $ensure == 'present' {
        file { "/etc/uwsgi/apps-available/${basename}.ini":
            content => template('uwsgi/app.ini.erb'),
        }

        if $enabled == true {
            file { "/etc/uwsgi/apps-enabled/${basename}.ini":
                ensure => link,
                target => "/etc/uwsgi/apps-available/${basename}.ini",
                notify => Service['uwsgi'],
            }
        }
    }
}
