# == systemd::unmask ===
#
# Use 'systemctl unmask $title' to undo the effects of systemctl mask so that
# the given unit can be started again.
#
# Example:
#  systemd::unmask { 'trafficserver-backend.service': }
#
define systemd::unmask (
    Systemd::Servicename $unit = $title,
    Boolean $refreshonly = true,
){
    exec { "unmask_${unit}":
        command     => "/bin/systemctl unmask ${unit}",
        onlyif      => "/bin/readlink -f /etc/systemd/system/${unit} | grep -q /dev/null",
        refreshonly => $refreshonly,
    }
}
