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

    file { "/usr/lib/tmpfiles.d/thumbor@${port}.conf":
        content => template('thumbor/thumbor.tmpfiles.d.erb'),
    }

    exec { "create-tmp-folder-${port}":
        command => '/bin/systemd-tmpfiles --create --prefix=/srv/thumbor/tmp',
        creates => "/srv/thumbor/tmp/thumbor@${port}",
        before  => Service["thumbor@${port}"],
    }

    service { "thumbor@${port}":
        ensure   => running,
        provider => 'systemd',
        enable   => true,
        require  => File['/lib/systemd/system/thumbor@.service'],
    }

    nrpe::monitor_systemd_unit_state{ "thumbor@${port}":
        retries => 15,
    }
}
