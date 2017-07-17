# == Class systemd ==
#
# This class just defines a guard against running on non-systemd systems, and
# a few constants.
#
class systemd {
    if $::initsystem != 'systemd' {
        fail(
            "You can only use systemd::file on systems with systemd, got ${::initsystem}"
        )
    }

    # Taken from `man systemd.unit` on systemd 215, still valid up to systemd 233
    $unit_types = [
        'service', 'socket', 'device', 'mount', 'automount',
        'swap', 'target', 'path', 'timer', 'snapshot', 'slice', 'scope'
    ]

    # Directories for base units and overrides
    $base_dir = '/lib/systemd/system/'
    $override_dir = '/etc/systemd/system/'
}
