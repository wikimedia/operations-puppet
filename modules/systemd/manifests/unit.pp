# == systemd::unit ===
#
# Defines a systemd unit file, properly handling dependencies of the
# corresponding service and reload of systemd.
#
# === Parameters ===
#
# [*content*]
#   The content of the file. Required.
# [*ensure*]
#   The usual meta-parameter, defaults to present. Valid values are
#   'absent' and 'present'
# [*restart*]
#   Whether to handle restarting the service when the file changes.
#
define systemd::unit(
    $content,
    $ensure  = 'present',
    $restart = false,
){
    $path = "/lib/systemd/system/${title}.service"

    systemd::file { $path:
        ensure       => present,
        content      => $content,
        service_name => $title,
        restart      => $restart
    }
}
