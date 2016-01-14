# FIXME: This is currently not enabled and configured. To be done.
#
# The user-facing webapp that can be used to generate one off visual diffs.
#
# === Parameters
#
# [*instance_name*]
#   Name of the visual-diffing service.
#
# [*webapp_port*]
#   The port for the webapp.
#   Default: 8012.
#
define visualdiff::server(
    $instance_name,
    $webapp_port = 8012,
) {
    file { "/etc/visualdiff/${instance_name}.config.js":
        content => template("visualdiff/${instance_name}.settings.js.erb"),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service[$instance_name],
    }

    file { "/etc/init/${instance_name}.conf":
        source => "puppet:///modules/visualdiff/${instance_name}.upstart.conf",
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service[$instance_name],
    }

    service { $instance_name:
        ensure   => running,
        provider => upstart,
    }
}
