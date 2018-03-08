# == Class systemd ==
#
# This class just defines a guard against running on non-systemd systems, and
# a few constants.
#
class systemd {
    if $::initsystem != 'systemd' {
        fail(
            "You can only use systemd resources on systems with systemd, got ${::initsystem}"
        )
    }

    # Directories for base units and overrides
    $base_dir = '/lib/systemd/system'
    $override_dir = '/etc/systemd/system'
}
