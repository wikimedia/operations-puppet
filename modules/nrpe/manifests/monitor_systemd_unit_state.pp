# === Define: nrpe::monitor_systemd_unit_lastrun
#
# Installs a check for last run time of a systemd unit using journalctl
define nrpe::monitor_systemd_unit_lastrun(
    $unit = $title,
    $description = "${unit} last run",
    $contact_group = 'admins',
    $retries = 3,
    $timeout = 10,
    $critical = false,
    $ensure = 'present',
    $warn_secs = 60*60*25,
    $crit_secs = 60*60*49,
    ){

    if $::initsystem != 'systemd' {
        fail('nrpe::monitor_systemd_unit_lastrun can only work on systemd-enabled systems')
    }
    require nrpe::systemd_scripts

    # Temporary hack until we fix the downstream modules
    if $critical {
        $nagios_critical = 'true'
    } else {
        $nagios_critical = 'false'
    }

    nrpe::monitor_service { "${unit}-lastrun":
        ensure       => $ensure,
        description  => $description,
        nrpe_command => "/usr/local/bin/nrpe_check_systemd_unit_lastrun '${unit}' ${warn_secs} ${crit_secs}",
        retries      => $retries,
        timeout      => $timeout,
        critical     => $nagios_critical,
    }
}
