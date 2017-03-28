# == Class: parsoid
#
# Parsoid is a wt2HTML and HTML2wt parser able to deliver no-diff round-trip
# conversions between the two formats.
#
# === Parameters
#
# [*port*]
#   Port to run the Parsoid service on. Default: 8000
#
# [*settings_file*]
#   Location of the old-format Parsoid configuration and settings file. Note
#   that Parsoid still draws part of its configuration from there when it is
#   specified. Default: 'conf/wmf/localsettings.js'
#
# [*logging_name*]
#   The logging name to send to logstash. Default: 'parsoid'
#
# [*statsd_prefix*]
#   The statsd metric prefix to use. Default: 'parsoid'
#
# [*deployment*]
#   Deployment system to use: available are trebuchet, scap3 or git.
#   Default: scap3
#
# [*mwapi_server*]
#   The full URI of the MW API endpoint to contact when issuing direct
#   requests to it. Default: ''
#
# [*mwapi_proxy*]
#   The proxy to use to contact the MW API. Note that you usually want to set
#   either mwapi_server or this variable. Do not set both! Default:
#   'http://api.svc.eqiad.wmnet'
#
class parsoid(
    $port          = 8000,
    $settings_file = 'conf/wmf/localsettings.js',
    $logging_name  = 'parsoid',
    $statsd_prefix = 'parsoid',
    $deployment    = 'scap3',
    $mwapi_server  = '',
    $mwapi_proxy   = 'http://api.svc.eqiad.wmnet',
) {

    service::node { 'parsoid':
        port              => $port,
        starter_module    => 'src/lib/index.js',
        entrypoint        => 'apiServiceWorker',
        starter_script    => 'src/bin/server.js',
        # NOTE: this is useful only when deployment == 'git'
        config            => {
            localsettings => $settings_file,
        },
        heap_limit        => 800,
        heartbeat_to      => 180000,
        healthcheck_url   => '/',
        has_spec          => false,
        logging_name      => $logging_name,
        statsd_prefix     => $statsd_prefix,
        auto_refresh      => false,
        deployment        => $deployment,
        deployment_config => false,
    }

    service::node::config::scap3 { 'parsoid':
        port            => $port,
        starter_module  => 'src/lib/index.js',
        entrypoint      => 'apiServiceWorker',
        heap_limit      => 800,
        heartbeat_to    => 180000,
        statsd_prefix   => $statsd_prefix,
        auto_refresh    => false,
        deployment_vars => {
            mwapi_server => $mwapi_server,
            mwapi_proxy  => $mwapi_proxy,
        },
    }
}
