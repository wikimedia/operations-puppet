# @summary
#   Use 'systemctl unmask $title' to undo the effects of systemctl mask so that
#   the given unit can be started again.
#
# @example
#  systemd::unmask { 'trafficserver-backend.service': }
#
# @param unit the unit name to unmask
# @param refreshonly set refreshonly value
define systemd::unmask (
    Systemd::Unit::Name $unit        = $title,
    Boolean             $refreshonly = true,
) {
    exec { "unmask_${unit}":
        command     => "/bin/systemctl unmask ${unit}",
        onlyif      => "/bin/readlink -f /etc/systemd/system/${unit} | grep -q /dev/null",
        refreshonly => $refreshonly,
    }
}
