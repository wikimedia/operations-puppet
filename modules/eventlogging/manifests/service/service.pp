# == Define eventlogging::service::service
# HTTP Produce Service for EventLogging
#
# == Parameters
#
# TODO: is this really what we want to call this class?!?
define eventlogging::service::service(
    $schemas_path,
    $topic_config,
    $outputs,
    $port = undef, # default 8085
    # TODO: Where does this go with scap3?
    $executable = undef,
    $log_file = undef,
    $log_config_template = 'eventlogging/log.cfg.erb',
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
    $config_file = "/etc/eventlogging.d/services/${basename}"

    if $log_config_template {
        # Configure logging
        $log_config = "/etc/eventlogging.d/services/eventlogging-service-${basename}-log.cfg"
        # If $log_file was not passed, default to this.
        $_log_file = $log_file ? {
            undef => "${::eventlogging::log_dir}/eventlogging-service-${basename}.log",
            default => $log_file,
        }

        file { $log_config:
            ensure  => $ensure,
            content => template($log_config_template)
        }
    }

    # render the eventlogging-service argparse config file
    file { $config_file:
        ensure  => $ensure,
        content => template('eventlogging/service.erb'),
    }

    # Use systemd for this eventlogging-service instance
    base::service_unit { "eventlogging-service-${basename}":
        template_name => 'service',
        systemd => true,
        refresh => false,
    }
}
