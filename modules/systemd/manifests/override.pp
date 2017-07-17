# == systemd::override ===
#
# Defines a systemd override file, properly handling dependencies of the
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
define systemd::override(
    $ensure = present,
    $content = undef,
    $restart = false,
){
    validate_ensure($ensure)
    $systemd_override_dir = "/etc/systemd/system/${name}.service.d"

    $override = "${systemd_override_dir}/puppet-override.conf"
    if !defined(File[$systemd_override_dir]) {
        file { "/etc/systemd/system/${title}.service.d":
            ensure => ensure_directory($ensure),
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
        }
    }

    systemd::file { $override:
        ensure       => $ensure,
        content      => $content,
        service_name => $title,
        restart      => $restart
    }
}
