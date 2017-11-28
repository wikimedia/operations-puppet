# == udev::rule ==
#
# Add a custom udev rule and reload udev
#
# === Parameters ===
# [*content*]
#   The content of the rule.
# [*source*]
#   The source of the rule. Either this or content must be set.
# [*ensure*]
#   The usual meta-parameter, defaults to present. Valid values are
#   'absent' and 'present'
# [*priority*]
#   The rule priority.

define udev::rule (
    $content = undef,
    $source = undef,
    $ensure = 'present',
    $priority = 40,
) {
    validate_ensure($ensure)

    include udev

    file { "/etc/udev/rules.d/${priority}-${title}.rules":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => $content,
        source  => $source,
        notify  => Exec['udev_reload'],
    }
}
