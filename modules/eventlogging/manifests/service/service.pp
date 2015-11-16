# == Define eventlogging::service::service
# HTTP Produce Service for EventLogging
#
# This service is configured using systemd.  To see logs and error output, do
#   journalctl -f -u eventlogging-service-$name
#
# == Parameters
#
# [*outputs*]
#   Array of EventLogging output URIs.
#
# [*schemas_path*]
#   Path to schemas repository.  JSONSchema files will be preloaded
#   and cached out of this directory.
#   Default: $eventlogging::package::path/config/schemas/jsonschema
#
# [*topic_config*]
#   Path to topic config file.  This file specifies what schema names
#   are allowed to be produced to which topics.
#   Default: /etc/eventlogging.d/topics.yaml
#
# [*port*]
#   Port on which this service will listen.  Default: undef (8085).
#
# [*num_processes*]
#   Number of processors for Tornado to start.  Each will listen
#   on $port.  Default: undef (1).  Instead of increasing this,
#   you may want to consider deploying several of these services
#   each listening on a different port and load balanced.  This
#   may be easier to monitor.
#
# [*executable*]
#   Path to eventlogging-service executable.
#   Default: $eventlogging::package::path/bin/eventlogging-service
#
# [*log_file*]
#   Output log file for this service.
#   Default: $eventlogging::log_dir/eventlogging-service_${basename}.log
#
# [*log_config_template*]
#   Path to ERb template to reconfigure logging.  You probably don't need to
#   change this.  Default: eventlogging/log.cfg.erb
#
define eventlogging::service::service(
    $schemas_path,
    $topic_config,
    $outputs,
    $port                = undef, # default 8085
    $num_processes       = undef, # default 1
    $executable          = undef,
)
{
    require ::eventlogging

    $executable_path = $executable ? {
        undef   => "${eventlogging::package::path}/bin/eventlogging-service",
        default => $executable,
    }
    $working_path = $eventlogging::package::path

    # Additional packages needed for eventlogging-service.

    # Can't use require_package here because we need to specify version
    # from jessie-backports:
    # https://packages.debian.org/jessie-backports/python-tornado
    if !defined(Package['python-tornado']) {
        package { 'python-tornado':
            ensure => '4.2.0-1~bpo8+1'
        }
    }

    $basename = regsubst($title, '\W', '-', 'G')
    $service_name = "eventlogging-service-${basename}"
    $config_file = "/etc/eventlogging.d/services/${basename}"

    # render the eventlogging-service argparse config file
    file { $config_file:
        ensure  => $ensure,
        content => template('eventlogging/service.erb'),
    }

    # Use systemd for this eventlogging-service instance.
    base::service_unit { $service_name:
        template_name => 'service',
        systemd       => true,
        refresh       => false,
        require       => [
            File[$config_file],
            Package['python-tornado'],
        ]
    }

    # Generate icinga alert if eventlogging-service-$basename is not running.
    nrpe::monitor_service { $service_name:
        description  => "Check that ${service_name} is running",
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -C '${$executable_path} @${config_file}",
        require      => Base::Service_unit[$service_name],
    }
}
