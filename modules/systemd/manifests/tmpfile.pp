# == systemd::tmpfile ==
#
# This define creates a systemd tmpfiles.d configuration snippet
#
# === Parameters ===
# The resource title is the basename of the resulting config file (the
# .conf is automatically appended)
#
# [*content*]
#   The content of the file. Required.
# [*ensure*]
#   The usual meta-parameter, defaults to present. Valid values are
#   'absent' and 'present'
# [*u_owner*]
#   The owner of the file. Defaults to root, but can be overridden if
#   the config file needs to be read by some daemon
# [*g_owner*]
#   The group owner of the file. Defaults to root, but can be
#   overridden if the config file needs to be read by some daemon
#
define systemd::tmpfile(
    $content,
    $ensure=present,
    $u_owner='root',
    $g_owner='root',
){
    $conf_path = "/etc/tmpfiles.d/${title}.conf"

    file { $conf_path:
        ensure  => $ensure,
        content => $content,
        mode    => '0444',
        owner   => $u_owner,
        group   => $g_owner,
    }
}
