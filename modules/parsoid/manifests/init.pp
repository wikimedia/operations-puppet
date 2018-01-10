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
# [*conf*]
#   Hash or YAML-formatted string that gets merged into the service's
#   configuration.  Only applicable for non-scap3 deployments.
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
# [*discovery*]
#   If defined, will use that discovery key to discover if the current datacenter is active
#   for the MediaWiki API, and use HTTP or HTTPS to connect the host ${discovery}.discovery.wmnet
#
class parsoid(
    $port          = 8000,
    $conf          = undef,
    $no_workers    = 'ncpu',
    $logging_name  = 'parsoid',
    $statsd_prefix = 'parsoid',
    $deployment    = 'scap3',
    $mwapi_server  = '',
    $mwapi_proxy   = 'http://api.svc.eqiad.wmnet',
    $discovery     = undef,
) {

    service::node { 'parsoid':
        port              => $port,
        starter_script    => 'src/bin/server.js',
        healthcheck_url   => '/',
        has_spec          => false,
        logging_name      => $logging_name,
        auto_refresh      => false,
        deployment        => $deployment,
        deployment_config => false,
        full_config       => 'external',
    }


    if ($deployment == 'scap3') {
        $confd_template = template('parsoid/confd_snippet.erb')
        # TODO: this is not needed in puppet 4
        if $discovery {
            $deployment_vars = {}
            class { '::confd':
                prefix   => hiera('conftool_prefix'),
                interval => 60,
            }
        } else {
            $deployment_vars = {
                mwapi_server => $mwapi_server,
                mwapi_proxy  => $mwapi_proxy,
            }
        }

        service::node::config::scap3 { 'parsoid':
            port            => $port,
            starter_module  => 'src/lib/index.js',
            entrypoint      => 'apiServiceWorker',
            logging_name    => $logging_name,
            heap_limit      => 800,
            heartbeat_to    => 180000,
            statsd_prefix   => $statsd_prefix,
            auto_refresh    => false,
            deployment_vars => $deployment_vars,
            discovery       => $discovery,
            confd_template  => $confd_template,
        }
    } else {
        service::node::config { 'parsoid':
            port           => $port,
            config         => $conf,
            no_workers     => $no_workers,
            starter_module => 'src/lib/index.js',
            entrypoint     => 'apiServiceWorker',
            logging_name   => $logging_name,
            heap_limit     => 800,
            heartbeat_to   => 180000,
            statsd_prefix  => $statsd_prefix,
            auto_refresh   => false,
        }
    }
}
