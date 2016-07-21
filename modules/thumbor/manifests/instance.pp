# == Define: thumbor::instance
#
# Sets up a new Thumbor instance.
#
# === Parameters
#
# [*title*]
#   This instance's listening port.
#
# === Examples
#
#   thumbor::instance { '8888': }
#
define thumbor::instance
{
    $port = $name
    $instance_service_path = "/lib/systemd/system/thumbor@${port}.service"
    $template_service_path = '/lib/systemd/system/thumbor@.service'

    file { $instance_service_path:
        ensure  => 'link',
        target  => $template_service_path,
        require => File[$template_service_path],
    }

    service { "thumbor@${port}":
        ensure   => running,
        provider => 'systemd',
        enable   => true,
        require  => File[$instance_service_path],
    }

    nrpe::monitor_systemd_unit_state{ "thumbor@${port}": }
}
