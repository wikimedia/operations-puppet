# == systemd::file ==
#
# This define creates a file on the filesystem at $path,
# schedules a daemon-reload of systemd and, if requested,
# schedules a subsequent refresh of the service.
#
# === Parameters ===
#
# [*content*]
#   The content of the file. Required.
# [*service_name*]
#   The name of the service this file refers to. Required.
# [*ensure*]
#   The usual meta-parameter, defaults to present. Valid values are
#   'absent' and 'present'
# [*restart*]
#   Whether to handle restarting the service when the file changes.
#
define systemd::file(
    $content,
    $service_name,
    $ensure=present,
    $restart=false
){
    require ::systemd
    file { $title:
        ensure  => $ensure,
        content => $content,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        notify  => Exec['systemd daemon-reload'],
    }

    # If the service is defined, add a dependency. If automatic restarts
    # are requested, also refresh the service resource.
    if defined(Service[$service_name]) {
        if $restart {
            # Refresh the service
            File[$title] ~> Service[$service_name]
        } else {
            File[$title] -> Service[$service_name]
        }
    }
}
