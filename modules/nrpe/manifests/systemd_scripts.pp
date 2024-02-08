# === Class nrpe::systemd_scripts
#
# Class that collects all systemd-related monitoring scripts.
#

class nrpe::systemd_scripts {
    nrpe::plugin { 'check_systemd_unit_state':
        ensure => absent,
    }
}
