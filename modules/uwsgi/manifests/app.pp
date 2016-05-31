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
#
# [*plugins*]
#   Comma-separated string list of plugins that will be passed to uwsgi as a
#   cmd line parameter instead of being written to the ini file.
#   Uwsgi uses a top-bottom, expand asap processing for options specified in the
#   config files, and sometimes does things like setting python environments
#   based on the occurrence of options like callable before it encounters the
#   plugin option that declares whether to use python 2 or 3.
#   The order of the config specified in a puppet dict (that has no ordering
#   guarantees) is lost prior to it being written to ini config in the
#   app.ini.erb template, and options aren't ordered in the intended manner.
#   Let's override the plugins option by passing it in the command line which
#   takes precedence over the options in the config file.
#
# === Examples
#
#  uwsgi::app { 'graphite-web':
#    settings => {
#      uwsgi => {
#          'socket'      => '/var/run/graphite-web/graphite-web.sock',
#          'wsgi-file'   => '/usr/share/graphite-web/graphite.wsgi',
#          'master'      => true,
#          'processes'   => 4,
#          'env'         => ['MYSQL_HOST=localhost', 'STATSD_PREFIX=wat'],
#      },
#    },
#    plugins => 'python, router_redirect'
#  }
#
define uwsgi::app(
    $settings,
    $plugins  = undef,
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
            $inipath =  "/etc/uwsgi/apps-enabled/${basename}.ini"
            file { $inipath:
                ensure => link,
                target => "/etc/uwsgi/apps-available/${basename}.ini",
            }

            base::service_unit { "uwsgi-${title}":
                ensure        => present,
                template_name => 'uwsgi',
                systemd       => true,
                upstart       => true,
                subscribe     => File["/etc/uwsgi/apps-available/${basename}.ini"],
            }

            nrpe::monitor_service { "uwsgi-${title}":
                description  => "${title} uWSGI web app",
                nrpe_command => "/usr/sbin/service uwsgi-${title} status",
                require      => Base::Service_unit["uwsgi-${title}"],
            }
        }
    }
}
