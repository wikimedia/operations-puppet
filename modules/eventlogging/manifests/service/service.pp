# == Define eventlogging::service::service
# HTTP Produce Service for EventLogging
#
# == Parameters
#
# [*outputs*]
#   Array of EventLogging output URIs.
#
# [*schemas_path*]
#   Path to schemas repository.  JSONSchema files will be preloaded
#   and cached out of this directory.
#
# [*topic_config*]
#   Path to topic config file.  This file specifies what schema names
#   are allowed to be produced to which topics.
#
# [*port*]
#   Port on which this service will listen.  Default: 8085.
#
# [*num_processes*]
#   Number of processors for Tornado to start.  Each will listen
#   on $port.  Default: undef (1).  Instead of increasing this,
#   you may want to consider deploying several of these services
#   each listening on a different port and load balanced.  This
#   may be easier to monitor.
#
# [*log_file*]
#   Output log file for this service.
#   Default: $eventlogging::log_dir/eventlogging-service-${basename}.log
#
# [*log_config_template*]
#   Path to ERb template to reconfigure logging.  You probably don't need to
#   change this.  Default: eventlogging/log.cfg.erb
#
# [*reload_on]
#   Reload eventlogging-service if any of the provided Puppet
#   resources have changed.  This should be an array of alreday
#   declared puppet resources.  E.g.
#   [File['/path/to/topicconfig.yaml'], Class['::something::else']]
#
define eventlogging::service::service(
    $schemas_path,
    $topic_config,
    $outputs,
    $port                = 8085,
    $num_processes       = undef, # default 1
    $log_file            = undef,
    $log_config_template = 'eventlogging/log.cfg.erb',
    $statsd              = 'localhost:8125',
    $statsd_prefix       = "eventlogging.service.${title}",
    $statsd_use_hostname = false,
    $reload_on           = undef,
)
{
    Class['eventlogging::server'] -> Eventlogging::Service::Service[$title]

    include ::rsyslog
    include service::monitoring

    # Additional packages needed for eventlogging-service that are not
    # provided by the eventlogging::dependencies class.

    # Can't use require_package here because we need to specify version
    # from jessie-backports:
    # https://packages.debian.org/jessie-backports/python-tornado
    if !defined(Package['python-tornado']) {
        package { 'python-tornado':
            ensure => '4.2.0-1~bpo8+1'
        }
    }
    # This allows tornado to automatically send stats to statsd.
    require_package('python-sprockets-mixins-statsd')

    # eventlogging will run out of the path configured in the
    # eventlogging::server class.
    $eventlogging_path = $eventlogging::server::eventlogging_path

    $basename = regsubst($title, '\W', '-', 'G')
    # $service_name is used in log.cfg.erb and in rsyslog.conf.erb
    $service_name = "eventlogging-service-${basename}"
    $config_file = "/etc/eventlogging.d/services/${basename}"
    $log_config_file = "/etc/eventlogging.d/services/${basename}.log.cfg"

    # Default log file is $service_name.log.
    # This will be written to by rsyslog matching
    # for $service_name.
    $_log_file = $log_file ? {
        undef => "${eventlogging::server::log_dir}/${service_name}.log",
        default => $_log_file,
    }

    # Rsyslog configuration that routes logs to a file.
    file { "/etc/rsyslog.d/80-${service_name}.conf":
        # FIXME - top-scope var without namespace, will break in puppet 2.8
        # lint:ignore:variable_scope
        ensure  => $ensure,
        # lint:endignore
        content => template('eventlogging/rsyslog.conf.erb'),
        mode    => '0444',
        notify  => Service['rsyslog'],
    }
    # Python logging conf file that properly formats
    # output with $programname prefix so that rsyslog
    # can properly route logs.
    file { $log_config_file:
        # FIXME - top-scope var without namespace, will break in puppet 2.8
        # lint:ignore:variable_scope
        ensure  => $ensure,
        # lint:endignore
        content => template('eventlogging/log.cfg.erb'),
        mode    => '0444',
    }
    # Python argparse config file for eventlogging-service
    file { $config_file:
        # FIXME - top-scope var without namespace, will break in puppet 2.8
        # lint:ignore:variable_scope
        ensure  => $ensure,
        # lint:endignore
        content => template('eventlogging/service.erb'),
        mode    => '0444',
        require => File[$log_config_file],
    }

    # Use systemd for this eventlogging-service instance.
    base::service_unit { $service_name:
        template_name => 'service',
        systemd       => true,
        refresh       => false,
        require       => [
            File[$config_file],
            File["/etc/rsyslog.d/80-${service_name}.conf"],
            Package['python-tornado'],
        ]
    }

    # eventlogging-service can be SIGHUPed via service reload.
    # E.g. if topic config or schemas change, a reload
    # will cause eventlogging-service to reload these.
    # Note that this does not restart the service, so no
    # requests in flight should be lost.
    # This will only happen if $reload_on is provided.
    exec { "reload ${service_name}":
        command     => "/bin/systemctl reload ${service_name}",
        refreshonly => true,
        subscribe   => $reload_on,
    }

    # Generate icinga alert if eventlogging-service-$basename is not running.
    nrpe::monitor_service { $service_name:
        description  => "Check that ${service_name} is running",
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: -C python -a '${eventlogging_path}/bin/eventlogging-service @${config_file}'",
        require      => Base::Service_unit[$service_name],
    }

    # Spec-based monitoring
    $monitor_url = "http://${::ipaddress}:${port}"
    nrpe::monitor_service{ "endpoints_${service_name}":
        description  => "${service_name} endpoints health",
        nrpe_command => "/usr/bin/service-checker-swagger -t 5 ${::ipaddress} ${monitor_url}",
    }
}
