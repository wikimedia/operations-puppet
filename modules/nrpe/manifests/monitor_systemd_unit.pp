# === Define: nrpe::monitor_systemd_unit
#
# Installs a check for a systemd unit using systemctl
define nrpe::monitor_systemd_unit(
    $description = "${title} service",
    $contact_group = 'admins',
    $retries = 3,
    $timeout = 10,
    $critical = false,
    $ensure = 'present',
    $expected_state = 'active'
    ){

    if $::initsystem != 'systemd' {
        fail("nrpe::monitor_systemd_unit can only work on systemd-enabled systems")
    }
    require nrpe::systemd_scripts

    # Temporary hack until we fix the downstream modules
    if $critical {
        $nagios_critical = 'true'
    } else {
        $nagios_critical = 'false'
    }

    nrpe::monitor_service { $title:
        ensure       => $ensure,
        description  => $description,
        nrpe_command => "/usr/local/bin/nrpe_check_systemd_state -s '${title}' -e ${expected_state}",
        retries      => $retries,
        timeout      => $timeout,
        critical     => $nagios_critical,
    }
}
