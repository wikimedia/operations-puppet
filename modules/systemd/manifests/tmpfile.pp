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
# [*owner*]
#   The owner of the file. Defaults to root, but can be overridden if
#   the config file needs to be read by some daemon
# [*group*]
#   The group owner of the file. Defaults to root, but can be
#   overridden if the config file needs to be read by some daemon
#
define systemd::tmpfile(
    $content,
    $ensure=present,
    $owner='root',
    $group='root',
){
    $conf_path = "/etc/tmpfiles.d/${title}.conf"

    if ('/' in $title){
        fail("Invalid title ${title}")
    }

    file { $conf_path:
        ensure  => $ensure,
        content => $content,
        mode    => '0444',
        owner   => $owner,
        group   => $group,
    }
}
